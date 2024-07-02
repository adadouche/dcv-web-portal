import base64
import hmac
import hashlib
import json
import os
import urllib3

import boto3
import logging

# create logger
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

http = urllib3.PoolManager()

sm_client = boto3.client("secretsmanager")
cognito_client = boto3.client("cognito-idp")

secret = json.loads(
    sm_client.get_secret_value(
        SecretId=os.environ["CLIENT_SECRET_ARN"],
    )["SecretString"]
)

USER_POOL_ID = secret["user-pool-id"]
CLIENT_SECRET = secret["client-secret"]

COGNITO_URL = os.environ["COGNITO_URL"]


def lambda_handler(event, context):
    """
    lambda_handler is a wrapper around the real handler that does some input normalization
    and exception handling so that the real handler is easier to understand.
    """
    try:
        # normalize method into lowercase for easier handling
        event["httpMethod"] = event["httpMethod"].lower()

        # normalize headers into lowercase for easier handling
        lowercased_headers = dict()
        for k, v in event["headers"].items():

            key = k.lower()
            if key in lowercased_headers:
                print("headers with different case found")
                return bad_request()

            lowercased_headers[k.lower()] = v

        event["headers"] = lowercased_headers

        response = real_handler(event, context)

        # ensure that some basic security headers are always present
        if "headers" not in response:
            response["headers"] = dict()

        response["headers"][
            "strict-transport-security"
        ] = "max-age=31536000; includeSubdomains"
        response["headers"]["cache-control"] = "no-store; max-age=0"

        response["headers"]["access-control-allow-origin"] = "*"
        response["headers"][
            "access-control-expose-headers"
        ] = "x-amzn-RequestId,x-amzn-ErrorType,x-amzn-ErrorMessage,Date"

        return response
    except json.decoder.JSONDecodeError as e:
        print(f"bad request: invalid JSON received: {e}")
        return bad_request()
    except TypeError as e:
        print(f"bad request: invalid type: {e}")
        # bad request where AuthParameters wasn't an object
        return bad_request()
    except KeyError as e:
        print(f"bad request: invalid request structure: missing key: {e}")
        # bad request that didn't have AuthParameters or AuthParameters wasn't an object
        return bad_request()
    except Exception as e:
        print(f"unexpected exception returned: {e}")
        return bad_request()


def real_handler(event, context):
    """
    real_handler actually handles the API Gateway Lambda proxy event. For a small set of requests,
    it will modify the request before forwarding on to Cognito; everything else is forwarded as-is.
    """
    body = json.loads(event["body"])

    # Cognito operation is carried in the `X-Amz-Target` header.
    # Extract that value so we can see what the caller is trying to do.
    operation = event["headers"]["x-amz-target"]

    if event["httpMethod"] == "post":
        if (
            operation == "AWSCognitoIdentityProviderService.InitiateAuth"
            and body.get("AuthFlow", None) == "REFRESH_TOKEN_AUTH"
        ):
            # Special case for REFRESH_TOKEN_AUTH since username is not part of the request, you only need to pass clientSecret as the secret_hash
            body["AuthParameters"]["SECRET_HASH"] = CLIENT_SECRET
            return proxy(operation, body, event["headers"])

        if operation == "AWSCognitoIdentityProviderService.InitiateAuth":
            # Convert InitiateAuth requests into AdminInitiateAuth requests.
            # Provide the secret hash so that Cognito will accept them.
            body["AuthParameters"]["SECRET_HASH"] = sign(
                f'{body["AuthParameters"]["USERNAME"]}{body["ClientId"]}'
            )

            if body["AuthFlow"] == "USER_PASSWORD_AUTH":
                body["AuthFlow"] = "ADMIN_USER_PASSWORD_AUTH"

            return send_to_cognito_with_context_data(
                body, event, cognito_client.admin_initiate_auth
            )

        if operation == "AWSCognitoIdentityProviderService.RespondToAuthChallenge":
            # Convert RespondToAuthChallenge requests into AdminRespondToAuthChallenge requests.
            # Provide the secret hash so that Cognito will accept them.
            body["ChallengeResponses"]["SECRET_HASH"] = sign(
                f'{body["ChallengeResponses"]["USERNAME"]}{body["ClientId"]}'
            )

            return send_to_cognito_with_context_data(
                body, event, cognito_client.admin_respond_to_auth_challenge
            )

        if (
            operation == "AWSCognitoIdentityProviderService.SignUp"
            or operation == "AWSCognitoIdentityProviderService.ConfirmSignUp"
            or operation == "AWSCognitoIdentityProviderService.ForgotPassword"
            or operation == "AWSCognitoIdentityProviderService.ConfirmForgotPassword"
            or operation == "AWSCognitoIdentityProviderService.ResendConfirmationCode"
        ):
            # Inject the SecretHash value so that these requests will be accepted.
            # Requests that don't go through this function won't be able to calculate
            # the SecretHash and will be rejected by Cognito.
            body["SecretHash"] = sign(f'{body["Username"]}{body["ClientId"]}')
            body["UserContextData"] = {
                "IpAddress": event["requestContext"]["identity"]["sourceIp"]
            }
            return proxy(operation, body, event["headers"])

    # All other requests just get forwarded as-is.
    return proxy(operation, body, event["headers"], method=event["httpMethod"])


def sign(content):
    """
    sign encapsulates the mechanism for creating an HMAC-SHA256 of the provided content. Cognito uses
    the HMAC to validate that the requester is in possession of the client secret, giving some protection
    against requests being sent directly to Cognito.
    """
    return base64.b64encode(
        hmac.new(
            bytes(CLIENT_SECRET, "utf-8"),
            msg=bytes(content, "utf-8"),
            digestmod=hashlib.sha256,
        ).digest()
    ).decode("utf-8")


def proxy(operation, body, headers, method="POST"):
    """
    proxy forwards the request to Cognito and processes the response.
    """
    print(f"Proxying request, operation={operation}")

    try:
        resp = http.request(
            method,
            COGNITO_URL,
            headers=headers,
            body=json.dumps(body) if body else None,
        )

        # need to convert from HTTPHeaderDict, also need to normalize case
        resp_headers = dict()
        for k, v in resp.headers.items():
            resp_headers[k.lower()] = v

        return {
            "statusCode": resp.status,
            "headers": resp_headers,
            "body": resp.data.decode("utf-8"),
        }
    except Exception as e:
        print(f"Error proxying request to Cognito: {e}")
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/x-amz-json-1.1",
            },
            "body": json.dumps({"message": "internal error"}),
        }


def send_to_cognito_with_context_data(body, event, fn):
    """
    send_to_cognito_with_context_details encapsulates some common parameter-setting and response handling
    for the Cognito SDK. It will call the provided SDK function `fn` with the enhanced `body` content.
    """
    body["UserPoolId"] = USER_POOL_ID

    body["ContextData"] = {
        "HttpHeaders": [
            {
                "headerName": "User-Agent",
                "headerValue": event["headers"]["user-agent"],
            },
        ],
        "IpAddress": event["requestContext"]["identity"]["sourceIp"],
        "ServerName": COGNITO_URL.rstrip("/"),
        "ServerPath": "/",
    }

    response = {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/x-amz-json-1.1",
        },
    }

    try:
        cognito_response = fn(**body)
        response["body"] = json.dumps(cognito_response)
    except cognito_client.exceptions.ClientError as error:
        print(error.response)
        response["statusCode"] = error.response["ResponseMetadata"]["HTTPStatusCode"]
        response["body"] = json.dumps(
            {
                "__type": error.response["Error"]["Code"],
                "message": error.response["Error"]["Message"],
            }
        )

    except Exception as e:
        print(f"Error sending request to Cognito: {e}")
        response["statusCode"] = 500
        response["body"] = json.dumps(
            {
                "__type": "InternalErrorException",
                "message": "An internal server error has occurred.",
            }
        )

    return response


def bad_request():

    return {
        "statusCode": 400,
        "headers": {
            "content-type": "application/x-amz-json-1.1",
            "strict-transport-security": "max-age=31536000; includeSubdomains",
            "cache-control": "no-store; max-age=0",
            "access-control-allow-origin": "*",
        },
        "body": json.dumps(
            {
                "__type": "InvalidParameterException",
                "message": "Invalid parameter value provided",
            }
        ),
    }
