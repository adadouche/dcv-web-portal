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

ADMIN_GROUP_NAME = os.environ['ADMIN_GROUP_NAME']
PROJECT          = os.environ['PROJECT']
APPLICATION      = os.environ['APPLICATION']
ENVIRONMENT      = os.environ['ENVIRONMENT']

def lambda_handler(event, context):
    # logger.debug(event)

    status_code = 200
    body    = {'error': True}
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,OPTIONS,POST,PUT,DELETE',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'
    }
    
    user_groups = ''
    username = ''
    includeTerminated = False
    try:
        user_groups       = event['requestContext']['authorizer']['claims']['cognito:groups']
        username          = event['requestContext']['authorizer']['claims']['cognito:username']
        includeTerminated = str(event['queryStringParameters']['includeTerminated']).lower() == 'true'
    except KeyError:
        user_groups = 'default'

    user_groups = user_groups.split(',')

    isAdmin = False
    if ADMIN_GROUP_NAME in user_groups:
        isAdmin = True

    filters = [
        {'Name': 'tag:project'    , 'Values': [PROJECT]},
        {'Name': 'tag:application', 'Values': [APPLICATION]},
        {'Name': 'tag:environment', 'Values': [ENVIRONMENT]},
        {'Name': 'tag:ui'         , 'Values': ['show']},
    ]
    
    if not isAdmin :        
        filters.append(
            {'Name': 'tag:username', 'Values': [username]},
        )
    instance_states = ['pending', 'running', 'shutting-down', 'stopping', 'stopped', 'terminated']
    if not includeTerminated:
        instance_states.remove('terminated')
    
    filters.append({'Name': 'instance-state-name', 'Values': instance_states},)

    describe_response = ec2.describe_instances(
        Filters=filters
    )
    
    # logger.debug(response)

    # only add instances if the cognito user group has an intersection with the user group tag from the launch instance
    data = []
    for reservation in describe_response['Reservations']:
        for instance in reservation['Instances']:
            tag_cognito_groups = ''.join([tag['Value'] for tag in instance['Tags'] if tag['Key']=='cognito_groups'])
            tag_cognito_groups = tag_cognito_groups.split(',')

            # in case the launch instance has no cognito_groups
            if len(tag_cognito_groups) == 0:
                tag_cognito_groups.append('default')
                
            intersection = list(set(user_groups) & set(tag_cognito_groups))

            if len(intersection) > 0 or ADMIN_GROUP_NAME in user_groups:
                # logger.debug(instance)
                data.append(
                    {
                        'instance_id'             : instance['InstanceId'],
                        'name'                    : ''.join([tag['Value'] for tag in instance['Tags'] if tag['Key']=='Name']),
                        'description'             : ''.join([tag['Value'] for tag in instance['Tags'] if tag['Key']=='Description']),
                        
                        'instance_state'          : instance['State']['Name'],
                        
                        'username'                : ''.join([tag['Value'] for tag in instance['Tags'] if tag['Key']=='username']),
                        'created_at'              : ''.join([tag['Value'] for tag in instance['Tags'] if tag['Key']=='created_at']),
                        'created_by'              : ''.join([tag['Value'] for tag in instance['Tags'] if tag['Key']=='created_by']),
                        'started_at'              : str(instance['LaunchTime']),
                                              
                        'launch_template_id'      : ''.join([tag['Value'] for tag in instance['Tags'] if tag['Key']=='launch_template_id']),
                        'launch_template_name'    : ''.join([tag['Value'] for tag in instance['Tags'] if tag['Key']=='launch_template_name']),
                        'launch_template_version' : ''.join([tag['Value'] for tag in instance['Tags'] if tag['Key']=='launch_template_version']),

                        'instance_family'         : instance['InstanceType'].split('.')[0],
                        'instance_size'           : instance['InstanceType'].split('.')[1],
                        'instance_type'           : instance['InstanceType'],

                        'os_family'               : ''.join([tag['Value'] for tag in instance['Tags'] if tag['Key']=='os_family']),
                        'os_platform'             : ''.join([tag['Value'] for tag in instance['Tags'] if tag['Key']=='os_platform']),

                        'dcv_status_configure'    : ''.join([tag['Value'] for tag in instance['Tags'] if tag['Key']=='status-nice-dcv-server-configure']),
                        'dcv_status_credentials'  : ''.join([tag['Value'] for tag in instance['Tags'] if tag['Key']=='status-nice-dcv-server-create-credentials']),

                        'hibernation_enabled'     : instance['HibernationOptions']['Configured']
                    }
                )
    instanceIds = [item['instance_id'] for item in data]
    
    status_response = ec2.describe_instance_status(
        InstanceIds=instanceIds,
    )

    for instance in data:        
        instance['dcv_status'] = None
        instance['instance_status_check'] = None

        if instance['instance_state'] != "running":
            continue

        for response_item in status_response['InstanceStatuses'] :
            if response_item["InstanceId"] == instance['instance_id']:

                if response_item['InstanceStatus']['Status'] == "ok" and response_item['SystemStatus']['Status'] == "ok":
                    instance['instance_status_check'] = "ok"
                elif response_item['InstanceStatus']['Status'] != "ok" or response_item['SystemStatus']['Status'] != "ok":
                    instance['instance_status_check'] = "initializing"
                else:
                    break    
        
        if instance['instance_status_check'] != "ok":
            continue

        if instance['dcv_status_configure'] == "completed" and instance['dcv_status_credentials'] == "completed":            
            instance['dcv_status'] = "ok"
        elif instance['dcv_status_configure'] == "failed" or instance['dcv_status_credentials'] == "failed":
            instance['dcv_status'] = "failed"
        elif instance['dcv_status_configure'] == "pending" or instance['dcv_status_credentials'] == "pending":
            instance['dcv_status'] = "pending"
        else:
            instance['dcv_status'] = None

    data = humps.camelize(data)    
    # logger.debug(data)

    body = {'instances': data} 
    
    return {
        'statusCode': status_code,
        'headers'   : headers,
        'body'      : json.dumps(body)
    }
