import os
import boto3
import secrets
import string

client = boto3.client('secretsmanager')
alphabet = string.ascii_letters + string.digits

def lambda_handler(event, context):
    # print(event)

    characters = string.ascii_letters + string.digits + "!?#@_-"
    password = ''.join(secrets.choice(characters) for i in range(12))
    
    # print(password)

    secret_name = os.environ['PREFIX'] + '-' + event['userName'] + '-credentials'
    
    # print(secret_name)
    
    secretExists = False
    try:
        describe_secret_response = client.describe_secret(
            SecretId=secret_name
        )
        secretExists = True
    except Exception as e:
      print("Execption while describing secret for " + event['userName'])
      print(e)
 
    tags = [
        {'Key': 'prefix',       'Value': os.environ['PREFIX']},
        {'Key': 'project',      'Value': os.environ['PROJECT']},
        {'Key': 'application',  'Value': os.environ['APPLICATION']},
        {'Key': 'environment',  'Value': os.environ['ENVIRONMENT']},
        {'Key': 'username',     'Value': event['userName']},
    ]

    if not secretExists :
        try:
            print("creating secret for " + event['userName'])
            client.create_secret(
                Name=secret_name,
                Description='Workstation password for ' + event['userName'],
                KmsKeyId=os.environ['KMS_KEY_ID'],
                SecretString=password,
                Tags=tags
            )
        except Exception as e:
          print("Unable to create secret for " + event['userName'])
          print(e)            
    else :
        needUpdate = False
        if 'DeletedDate' in describe_secret_response:
            print("restoring secret for " + event['userName'])
            
            try:
                restore_response = client.restore_secret(
                    SecretId=secret_name
                )
                needUpdate = True
            except Exception as e:
                print("Unable to restore secret for " + event['userName'])
                print(e)

        if describe_secret_response['KmsKeyId'] !=  os.environ['KMS_KEY_ID']:
            print("KMS Key Id is inconsistent for " + event['userName'] + "[current :" +  describe_secret_response['KmsKeyId'] + " - expected : " + os.environ['KMS_KEY_ID'] +"]")
            needUpdate = True
        
        if needUpdate:
            print("updating secret for " + event['userName'])
            
            try:
                update_secret_response = client.update_secret(
                    SecretId=secret_name,
                    Description='Workstation password for ' + event['userName'],
                    KmsKeyId=os.environ['KMS_KEY_ID'],
                    SecretString=password
                )
            except Exception as e:
                print("Unable to update secret for " + event['userName'])
                print(e)   
            try:
                tag_resource_response = client.tag_resource(
                    SecretId=secret_name,
                    Tags=tags
                )
            except Exception as e:
                print("Unable to tag secret for " + event['userName'])
                print(e)

    # you can use Amazon SES to send the password to the user (see https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ses/client/send_email.html)

    event['response']['autoConfirmUser']=True

    if 'email' in event['request']['userAttributes']:
        event['response']['autoVerifyEmail'] = True

    if 'phone_number' in event['request']['userAttributes']:
        event['response']['autoVerifyPhone'] = True

    return event
    