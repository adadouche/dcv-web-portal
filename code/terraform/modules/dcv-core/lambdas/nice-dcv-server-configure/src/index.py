# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import json
import os
import logging
import boto3

ec2 = boto3.client('ec2')
ssm = boto3.client('ssm')

# create logger
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

PROJECT = os.environ['PROJECT']
APPLICATION = os.environ['APPLICATION']
ENVIRONMENT = os.environ['ENVIRONMENT']
PREFIX = os.environ['PREFIX']

def lambda_handler(event, context):
    logger.debug(event)

    response_status_code = 200
    response_body = {'error': True}
    response_headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,OPTIONS,POST,PUT,DELETE',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'
    }

    try:
        body = json.loads(event['body'])
        instance_ids = body['instanceIds']
        document = body['document']
    except KeyError:
        return {
            'statusCode': response_status_code,
            'headers': response_headers,
            'body': json.dumps(response_body)
        }

    filters = [
        {'Name': 'tag:project', 'Values': [PROJECT]},
        {'Name': 'tag:application', 'Values': [APPLICATION]},
        {'Name': 'tag:environment', 'Values': [ENVIRONMENT]},
    ]

    document_short_name=f'nice-dcv-server-{document}'.lower()
    document_full_name=f'{PREFIX}-{document_short_name}'.lower()
    tag=f'status-{document_short_name}'.lower()

    logger.debug(instance_ids)
    logger.debug(document_full_name)
    logger.debug(tag)

    # we need to filter the instance ids that are not part of this deployment
    describe_response = ec2.describe_instances(
        Filters=filters,
        InstanceIds=instance_ids
    )


    # logger.debug(describe_response)

    # TODO: loop thr the instance Ids and build an array to call start_automation_execution once with all the instances
    # only add instances if the cognito user group has an intersection with the user group tag from the instance
    instanceIds = []
    for reservation in describe_response['Reservations']:
        for instance in reservation['Instances']:
            logger.debug(instance)
            
            instance_id = instance['InstanceId']
            logger.debug(instance_id)

            start_automation_execution_response = ssm.start_automation_execution(
                DocumentName=document_full_name,
                DocumentVersion='$DEFAULT',
                Parameters={
                    'InstanceId': [instance_id],
                    'prefix': [PREFIX],
                    'project': [PROJECT],
                    'application': [APPLICATION],
                    'environment': [ENVIRONMENT],
                }
            )
            # logger.debug(start_automation_execution_response)

            # set the dcv status tag
            ec2.create_tags(
                Resources=[instance_id],
                Tags=[{'Key': tag, 'Value': 'starting'},]
            )
    return {
        'statusCode': response_status_code,
        'headers': response_headers,
        'body': json.dumps(response_body, default=str)
    }
