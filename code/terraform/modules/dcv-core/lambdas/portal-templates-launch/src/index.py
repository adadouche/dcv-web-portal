# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import json
import os
import logging
import boto3
import datetime
import humps

ec2 = boto3.client('ec2')

# create logger
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

ADMIN_GROUP_NAME = 'cognito_group:{}'.format(os.environ['ADMIN_GROUP_NAME'])
PROJECT = os.environ['PROJECT']
APPLICATION = os.environ['APPLICATION']
ENVIRONMENT = os.environ['ENVIRONMENT']
DEFAULT_GROUP = ['cognito_group:default']

# TODO :
# - manage errors / issues more gracefully with error messages
# - check if input volumeSize, volumeIops and volumeThroughput are within the min / max values
# - if we want multiple volumes and network interface then the way we assign them need a revisit

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
        cognito_groups = event['requestContext']['authorizer']['claims']['cognito:groups'].split(
            ',')
        cognito_groups = ['cognito_group:'+value for value in cognito_groups]
        cognito_user = event['requestContext']['authorizer']['claims']['cognito:username']
        body = json.loads(event['body'])
    except KeyError:
        return {
            'statusCode': response_status_code,
            'headers': response_headers,
            'body': json.dumps(response_body)
        }

    # logger.debug(body)

    filters = [
        {'Name': 'tag:project', 'Values': [PROJECT]},
        {'Name': 'tag:application', 'Values': [APPLICATION]},
        {'Name': 'tag:environment', 'Values': [ENVIRONMENT]},
        {'Name': 'tag:ui', 'Values': ['show']},
    ]

    instances = []
    for item in body['items']:
        response_describe_launch_templates = ec2.describe_launch_templates(
            LaunchTemplateIds=[item['launchTemplateId']],
            Filters=filters
        )

        # logger.debug(response_describe_launch_templates)
        
        # only launch templates if the cognito user group has an intersection with the user group tag from the launch template
        data = []
        allowed = False
        for template in response_describe_launch_templates['LaunchTemplates']:
            tag_cognito_groups = ([tag['Key'] for tag in template['Tags'] if (
                tag['Key'].startswith('cognito_group:') and tag['Value'] == 'allowed')])
            intersection = list(set(cognito_groups) & set(tag_cognito_groups))
            if (len(tag_cognito_groups) > 0 and len(intersection) > 0) or ADMIN_GROUP_NAME in cognito_groups:
                allowed = True
        
        if allowed:
            response_describe_launch_template_versions = ec2.describe_launch_template_versions(
                LaunchTemplateId=item['launchTemplateId'],
                Versions=[str(item['launchTemplateVersion'])],
            )
            
            tag_subnetIds = ''.join([tag['Value'] for tag in template['Tags'] if tag['Key']=='subnets'])            

            SubnetId = get_launch_template_subnet(tag_subnetIds.split(','))

            # logger.debug(response_describe_launch_template_versions)
            
            BlockDeviceMapping = response_describe_launch_template_versions['LaunchTemplateVersions'][0]['LaunchTemplateData']['BlockDeviceMappings'][0]
            # logger.debug(BlockDeviceMapping)

            BlockDeviceMapping["Ebs"]['Iops'] = item['volumeIops']
            BlockDeviceMapping["Ebs"]['VolumeSize'] = item['volumeSize']
            BlockDeviceMapping["Ebs"]['VolumeType'] = item['volumeType']
            BlockDeviceMapping["Ebs"]['Throughput'] = item['volumeThroughput']

            NetworkInterface = response_describe_launch_template_versions['LaunchTemplateVersions'][0]['LaunchTemplateData']['NetworkInterfaces'][0]
            # logger.debug(NetworkInterfaces)
            NetworkInterface['SubnetId'] = SubnetId

            instance = ec2.run_instances(
                MaxCount=item['count'],
                MinCount=1,
                LaunchTemplate={
                    'LaunchTemplateId': item['launchTemplateId'],
                    'Version': str(item['launchTemplateVersion'])
                },
                BlockDeviceMappings=[BlockDeviceMapping],
                NetworkInterfaces=[NetworkInterface],
                TagSpecifications=[
                    {
                        'ResourceType': "instance",
                        'Tags': [
                            {
                                'Key': "username",
                                'Value': cognito_user
                            },
                            {
                                'Key': "created_by",
                                'Value': cognito_user
                            },
                            {
                                'Key': "created_at",
                                'Value': str(datetime.datetime.now())
                            },
                            {
                                'Key': "Name",
                                'Value': item['instanceName']
                            },
                            {
                                'Key': "Description",
                                'Value': item['instanceDescription']
                            },
                            {
                                'Key': "launch_template_id",
                                'Value': item['launchTemplateId']
                            },
                            {
                                'Key': "launch_template_name",
                                'Value': item['templateName']
                            },
                            {
                                'Key': "launch_template_version",
                                'Value': str(item['launchTemplateVersion'])
                            },
                            {
                                'Key': "ui",
                                'Value': "show"
                            }
                        ]
                    }
                ]
            )
        instances.append(instance)
        # logger.debug("tag_cognito_groups ok")
        # logger.debug(response)
    # logger.debug(data)

    instances = humps.camelize(instances)
    response_body = instances

    return {
        'statusCode': response_status_code,
        'headers': response_headers,
        'body': json.dumps(response_body, default=str)
    }


def get_launch_template_subnet(subnetIds):
    response_describe_subnets = ec2.describe_subnets(
        SubnetIds=subnetIds,
    )
    target_subnet = subnetIds[0]
    available_ips = 0
    for subnet in response_describe_subnets['Subnets']:
        if(subnet['AvailableIpAddressCount'] > available_ips) : 
            target_subnet = subnet['SubnetId']
            available_ips = subnet['AvailableIpAddressCount']

    return target_subnet