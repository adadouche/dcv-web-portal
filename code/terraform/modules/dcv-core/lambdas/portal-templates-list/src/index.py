# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import json
import os
import logging
import boto3
import humps

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

    status_code = 200
    body    = {'error': True}
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,OPTIONS,POST,PUT,DELETE',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'
    }
    
    cognito_groups = DEFAULT_GROUP
    
    try:
        cognito_groups = event['requestContext']['authorizer']['claims']['cognito:groups'].split(',')
        cognito_groups = ['cognito_group:'+value for value in cognito_groups]
    except KeyError:
        pass

    filters = [
        {'Name': 'tag:project'    , 'Values': [PROJECT]},
        {'Name': 'tag:application', 'Values': [APPLICATION]},
        {'Name': 'tag:environment', 'Values': [ENVIRONMENT]},

        {'Name': 'tag:ui'            , 'Values': ['show']},
        {'Name': 'tag:template_type' , 'Values': ['workstation']},
    ]
    
    # logger.debug(filters)
    
    response = ec2.describe_launch_templates(
        Filters=filters
    )
    
    # logger.debug(response)
    
    # only add templates if the cognito user group has an intersection with the user group tag from the launch template
    data = []
    for template in response['LaunchTemplates']:
        tag_cognito_groups = ([tag['Key'] for tag in template['Tags'] if (tag['Key'].startswith('cognito_group:') and tag['Value'] == 'allowed')])

        # logger.debug(tag_cognito_groups)
            
        intersection = list(set(cognito_groups) & set(tag_cognito_groups))
        if (len(tag_cognito_groups) > 0 and len(intersection) > 0) or ADMIN_GROUP_NAME in cognito_groups:
            tag_volume = json.loads(''.join([tag['Value'] for tag in template['Tags'] if tag['Key']=='volume']))

            data.append(
                 {
                    'id'               : template['LaunchTemplateId'],
                    'name'             : template['LaunchTemplateName'],
                    'description'      : ''.join([tag['Value'] for tag in template['Tags'] if tag['Key']=='description']),
                    'created_at'       : str(template['CreateTime']),
                    'created_by'       : template['CreatedBy'].split('/')[-1],
                    'default_version'  : template['DefaultVersionNumber'],
                    'latest_version'   : template['LatestVersionNumber'],

                    'os_family'        : ''.join([tag['Value'] for tag in template['Tags'] if tag['Key']=='os_family']),
                    'os_platform'      : ''.join([tag['Value'] for tag in template['Tags'] if tag['Key']=='os_platform']),
                    'os_version'       : ''.join([tag['Value'] for tag in template['Tags'] if tag['Key']=='os_version']),

                    'components'       : ''.join([tag['Value'] for tag in template['Tags'] if tag['Key']=='components_managed']),
                    'policies'         : ''.join([tag['Value'] for tag in template['Tags'] if tag['Key']=='policies_managed']),

                    'instance_families': (''.join([tag['Value'] for tag in template['Tags'] if tag['Key']=='instance_families'])).split(','),
                    'instance_sizes'   : (''.join([tag['Value'] for tag in template['Tags'] if tag['Key']=='instance_sizes'])).split(','),
                   
                    'volume_type'      : tag_volume["type"],
                    
                    'volume_size'      : tag_volume["size"]["default"],
                    'volume_size_min'  : tag_volume["size"]["min"],
                    'volume_size_max'  : tag_volume["size"]["max"],
                    
                    'volume_iops'      : tag_volume["iops"]["default"],
                    'volume_iops_min'  : tag_volume["iops"]["min"],
                    'volume_iops_max'  : tag_volume["iops"]["max"],
                    
                    'volume_throughput'      : tag_volume["throughput"]["default"],
                    'volume_throughput_min'  : tag_volume["throughput"]["min"],
                    'volume_throughput_max'  : tag_volume["throughput"]["max"],
                }
            )
            data = humps.camelize(data)
    # logger.debug(data)
    
    body = {'templates': data} 
    
    return {
        'statusCode': status_code,
        'headers'   : headers,
        'body'      : json.dumps(body)
    }
