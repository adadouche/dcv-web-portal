import boto3
import json

ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    # print(event)
    
    tag = event['tag']
    value = event['value']
    launch_template_ids = event['launchTemplateIds']

    ec2.create_tags(
        Resources=launch_template_ids, Tags=[{'Key': tag, 'Value': value},  ]
    )

        
        