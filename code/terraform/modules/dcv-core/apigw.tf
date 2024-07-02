# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  method_authorization_none    = "NONE"
  method_authorizer_none       = ""
  method_authorization_cognito = "COGNITO_USER_POOLS"
  method_authorizer_cognito    = aws_api_gateway_authorizer.api_authorizer.id
}

resource "aws_api_gateway_authorizer" "api_authorizer" {
  name          = "${var.env.prefix}-apigw-authorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.api_gateway_rest_api.id
  provider_arns = [var.module_authentication.user_pool.arn]
}

resource "aws_api_gateway_rest_api" "api_gateway_rest_api" {
  name        = "${var.env.prefix}-apigw"
  description = "[${var.env.prefix}] API Gateway"
  
  endpoint_configuration {
    vpc_endpoint_ids = (var.module_network.config.deployment_mode == "public" ? null : [local.vpc_endpoints["api-gateway"].id])
    types            = (var.module_network.config.deployment_mode == "public" ? ["REGIONAL"] : ["PRIVATE"])
  }
# policy = jsonencode(
  #   {
  #     "Version": "2012-10-17",
  #     "Statement": [{
  #         "Effect": "Allow",
  #         "Principal": "*",
  #         "Action": "execute-api:Invoke",
  #         "Resource": "execute-api:/*/*/*"
  #       },
  #       {
  #         "Effect": "Deny",
  #         "Principal": "*",
  #         "Action": "execute-api:Invoke",
  #         "Resource": "execute-api:/*/*/*",
  #         "Condition": {
  #           "NotIpAddress": {
  #             "aws:SourceIp": ["${join("\", \"", var.module_network.config.ip_allow_list)}"]
  #           }
  #         }
  #       }
  #     ]
  #   }  
  # )
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_rest_api_policy" "api_gateway_rest_api_policy" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway_rest_api.id

  policy = jsonencode(
     {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": "*",
                "Action": "execute-api:Invoke",
                "Resource": "${aws_api_gateway_rest_api.api_gateway_rest_api.execution_arn}/*"
            },
            # {
            #     "Effect": "Deny",
            #     "Principal": "*",
            #     "Action": "execute-api:Invoke",
            #     "Resource": "${aws_api_gateway_rest_api.api_gateway_rest_api.execution_arn}/*",
            #     "Condition": {
            #         "StringNotEquals": {
            #             "aws:SourceVpc": "${var.module_network.vpc.id}"
            #         }
            #     }
            # }
        ]
    } 
  )
}

# Force redeploy if any of "apigw-resources-*.tf" file in the current directory changes
resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  rest_api_id       = aws_api_gateway_rest_api.api_gateway_rest_api.id
  stage_description = "Deployed at ${timestamp()}"

  triggers = {
    redeployment_apigw_change = md5(join("", [for f in fileset(".", "**/apigw-resources-*.tf") : filemd5("./${f}")]))
    redeployment_body         = md5(jsonencode(aws_api_gateway_rest_api.api_gateway_rest_api.body))
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
  depends_on  = [
    module.cognito_methods,
    module.cognito_options,
    module.dcv_methods,
    module.portal_dcv_options,
    module.portal_dcv_function_post,
    module.portal_instances_options,
    module.portal_instances_list_get,
    module.portal_instances_function_post,
    module.portal_secret_options,
    module.portal_secret_get,
    module.portal_templates_options,
    module.portal_templates_list_get,
    module.portal_templates_launch_post
  ]
}

resource "aws_api_gateway_stage" "api_gateway_stage" {
  deployment_id        = aws_api_gateway_deployment.api_gateway_deployment.id
  rest_api_id          = aws_api_gateway_rest_api.api_gateway_rest_api.id
  xray_tracing_enabled = true
  stage_name           = "api"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.cloudwatch_log_group.arn
    format          = jsonencode(
      { 
        requestId         = "$context.requestId"
        extendedRequestId = "$context.extendedRequestId"
        ip                = "$context.identity.sourceIp"
        caller            = "$context.identity.caller"
        user              = "$context.identity.user"
        requestTime       = "$context.requestTime"
        httpMethod        = "$context.httpMethod"
        resourcePath      = "$context.resourcePath"
        status            = "$context.status"
        protocol          = "$context.protocol"
        responseLength    = "$context.responseLength"
      }
    )
  }
}

resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_account_cloudwatch.arn
  depends_on          = [aws_cloudwatch_log_group.cloudwatch_log_group]
}

resource "aws_api_gateway_method_settings" "api_gateway_method_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway_rest_api.id
  stage_name  = aws_api_gateway_stage.api_gateway_stage.stage_name
  method_path = "*/*"

  depends_on = [aws_api_gateway_account.api_gateway_account]

  settings {
    # Enable CloudWatch logging and metrics
    metrics_enabled    = true
    data_trace_enabled = false # set to true for development only
    logging_level      = "INFO"

    # Limit the rate of calls to prevent abuse and unwanted charges
    throttling_rate_limit  = 100
    throttling_burst_limit = 500
  }
}
