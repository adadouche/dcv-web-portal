# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import json
import os
import logging
import boto3
import base64

ec2 = boto3.client('ec2')

# create logger
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

ADMIN_GROUP_NAME = 'cognito_group:{}'.format(os.environ['ADMIN_GROUP_NAME'])
PROJECT          = os.environ['PROJECT']
APPLICATION      = os.environ['APPLICATION']
ENVIRONMENT      = os.environ['ENVIRONMENT']
DEFAULT_GROUP    = ['cognito_group:default']

def lambda_handler(event, context):
    # logger.debug(event)

    response_status_code = 200
    response_body = {'error': True}
    response_headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,OPTIONS,POST,PUT,DELETE',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'
    }
    
    cognito_groups = DEFAULT_GROUP
    cognito_user = ''
    body = {}
    try:
        cognito_groups = event['requestContext']['authorizer']['claims']['cognito:groups'].split(',')
        cognito_groups = ['cognito_group:' + value for value in cognito_groups]
        cognito_user   = event['requestContext']['authorizer']['claims']['cognito:username']
        body           = json.loads(event['body'])
    except KeyError:
        return {
            'statusCode': response_status_code,
            'headers': response_headers,
            'body': json.dumps(response_body)
        }
    
    filters = [
        {'Name': 'tag:project'    , 'Values': [PROJECT]},
        {'Name': 'tag:application', 'Values': [APPLICATION]},
        {'Name': 'tag:environment', 'Values': [ENVIRONMENT]},
        {'Name': 'tag:ui'         , 'Values': ['show']},
    ]

    isAdmin = False
    if ADMIN_GROUP_NAME in cognito_groups:
        isAdmin = True

    if not isAdmin :        
        filters.append(
            {'Name': 'tag:username', 'Values': [cognito_user]},
        )
    
    describe_response = ec2.describe_instances(
        Filters=filters,
        InstanceIds=body['instanceIds']
    )

    # logger.debug(describe_response)
    
    # only add instances if the cognito user group has an intersection with the user group tag from the instance
    instanceIds = []
    for reservation in describe_response['Reservations']:
        for instance in reservation['Instances']:
            tag_cognito_groups = ''.join([tag['Value'] for tag in instance['Tags'] if tag['Key']=='cognito_groups'])
            tag_cognito_groups = tag_cognito_groups.split(',')

            # in case the instance has no cognito_groups
            if len(tag_cognito_groups) == 0:
                tag_cognito_groups.append('default')
                
            intersection = list(set(cognito_groups) & set(tag_cognito_groups))

            if len(intersection) > 0 or ADMIN_GROUP_NAME in cognito_groups:
                instanceIds.append(instance['InstanceId'])

    if len(instanceIds) > 0 :
        stop_response = ec2.stop_instances(
            InstanceIds=instanceIds,
        )
        # clear the dcv status tag
        ec2.create_tags(
            Resources=instanceIds,
            Tags=[{ 'Key': 'dcv_status', 'Value': 'stopped'},]
        )
    
    response_body = stop_response['StoppingInstances']
    
    return {
        'statusCode': response_status_code,
        'headers': response_headers,
        'body': json.dumps(response_body, default=str)
    }
