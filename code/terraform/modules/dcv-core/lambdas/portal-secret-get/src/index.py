# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import json
import os
import logging
import boto3
import humps

secretsmanager = boto3.client('secretsmanager')

# create logger
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

ADMIN_GROUP_NAME = os.environ['ADMIN_GROUP_NAME']
PROJECT = os.environ['PROJECT']
APPLICATION = os.environ['APPLICATION']
ENVIRONMENT = os.environ['ENVIRONMENT']


def lambda_handler(event, context):
    # logger.debug(event)

    status_code = 200
    body = {'error': True}
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,OPTIONS,POST,PUT,DELETE',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'
    }

    user_groups = ''
    username = ''
    includeTerminated = False
    try:
        user_groups = event['requestContext']['authorizer']['claims']['cognito:groups']
        username = event['requestContext']['authorizer']['claims']['cognito:username']
    except KeyError:
        user_groups = 'default'

    user_groups = user_groups.split(',')
    secret_name = os.environ['PREFIX'] + '-' + username + '-credentials'

    filters = [

        {'Key': 'name', 'Values': [secret_name]},
        {'Key': 'tag-key', 'Values': ["project"]},
        {'Key': 'tag-key', 'Values': ["application"]},
        {'Key': 'tag-key', 'Values': ["environment"]},
        {'Key': 'tag-key', 'Values': ["username"]},
        {'Key': 'tag-value', 'Values': [PROJECT]},
        {'Key': 'tag-value', 'Values': [APPLICATION]},
        {'Key': 'tag-value', 'Values': [ENVIRONMENT]},
        {'Key': 'tag-value', 'Values': [username]},
    ]

    list_response = secretsmanager.list_secrets(
        IncludePlannedDeletion=False,
        Filters=filters
    )

    # logger.debug(response)

    # only add instances if the cognito user group has an intersection with the user group tag from the launch instance
    data = {}
    for secret in list_response['SecretList']:
        secret_value_response = secretsmanager.get_secret_value(
            SecretId=secret['Name']
        )

        data = {
            'SecretString': secret_value_response['SecretString'],
        }

    data = humps.camelize(data)
    # logger.debug(data)

    body = data

    return {
        'statusCode': status_code,
        'headers': headers,
        'body': json.dumps(body)
    }
