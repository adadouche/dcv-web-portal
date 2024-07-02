#!/bin/bash

#TODO : 
# - sg detach vpce
# - 

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

usage() {
    echo ""
    echo "./clean-up.sh <prefix_id> <account_id> <region> "
    echo "  - prefix_id  : the resource prefix (for example 'app-epu')"
    echo "  - account_id : the AWS Account id."
    echo "  - region     : the AWS Account region."
    echo ""
}

prefix_id=$1
if [ -z "$prefix_id" ]
then
    echo "Unable to run the script: prefix_id is not set";
    usage
    exit 1
fi

if [[ $prefix_id == "" ]]
then
    echo "Unable to run the script: prefix_id is not set";
    usage
    exit 1
fi

account_id=$2
if [[ $account_id == "" ]]
then
    account_id=$(aws sts get-caller-identity | jq .Account -r)
    if [[ $account_id == "" ]]
    then
        echo "Unable to run the script: account_id is not set";
        usage
        exit 1
    else
        echo "Using the current account_id: $account_id";
    fi
fi

region=$3
if [[ $region == "" ]]
then
    region=$(aws configure get region)
    if [[ $account_id == "" ]]
    then
        echo "Unable to run the script: region is not set";
        usage
        exit 1
    else
        echo "Using the current region: $region";
    fi
fi

GREEN=$'\e[0;32m'
RED=$'\e[0;31m'
NC=$'\e[0m'

echo ""
echo "Using :"
echo "  prefix_id  = $prefix_id";
echo "  account_id = $account_id";
echo "  region     = $region";
echo ""
echo "${RED} ****************************************************************************************************"
echo ""
echo "${RED} THIS SCRIPT WILL DESTROY RESOURCES BASED ON NAMES AND TAGS REGARDLESS OF THE WAY THEY WERE CREATED."
echo ""
echo "${RED} USE WITH CAUTION AND AT YOUR OWN RISK"
echo ""
echo "${RED} ****************************************************************************************************"
echo ""
read -p "Continue (y/n)? " choice
echo ""

case "$choice" in 
  y|Y ) echo "";;
  n|N ) exit 0;;
  * ) echo "invalid";;
esac

read -p "Are you sure you want to continue (y/n)? " choice
echo ""

case "$choice" in 
  y|Y ) echo "";;
  n|N ) exit 0;;
  * ) echo "invalid";;
esac

echo "${NC}"

echo disable cloudfront-distributions
for id in $(aws cloudfront list-distributions --query "DistributionList.Items[?( starts_with(Comment, '[$prefix_id' ) && Status == 'Deployed' ) ].Id"  --output text); do
    if [ "$id" == "None" ]; then
        break
    fi

    enabled=$(aws cloudfront list-distributions --query "DistributionList.Items[?( Id == '$id') ].Enabled"  --output text)

    if [ "$enabled" != "True" ]; then
        break
    fi

    echo "  $id - > $enabled"
    aws cloudfront get-distribution-config --id "$id" | jq .DistributionConfig.Enabled=false > cloudfront.json
    cat cloudfront.json | jq -r .DistributionConfig > distribution.json
    # Disable it first
    aws cloudfront update-distribution --id "$id" --if-match $(aws cloudfront get-distribution-config --id "$id" | jq .ETag -r) --distribution-config file://distribution.json > /dev/null
    rm cloudfront.json
    rm distribution.json

    echo -n "waiting for disable cloudfront-distributions"
    status=$(aws cloudfront list-distributions --query "DistributionList.Items[?starts_with(Id, '$id')].Status" --output text)
    while [ $status != "Deployed" ]; do 
        sleep 2s
        echo -n "."
        status=$(aws cloudfront list-distributions --query "DistributionList.Items[?starts_with(Id, '$id')].Status" --output text)
    done
    echo ""
    echo "completed for disable cloudfront-distributions"

done

echo delete cloudfront-distributions
for id in $(aws cloudfront list-distributions --query "DistributionList.Items[?starts_with(Comment, '[$prefix_id')].Id" --output text); do
    if [ "$id" == "None" ]; then
        break
    fi
    echo "  $id"
    aws cloudfront delete-distribution --id "$id" --if-match $(aws cloudfront get-distribution-config --id "$id" | jq .ETag -r)

    echo -n "waiting for delete cloudfront-distributions"
    status=$(aws cloudfront list-distributions --query "DistributionList.Items[?starts_with(Id, '$id')]" --output text)
    while [ $status != "None" ]; do 
        sleep 2s
        echo -n "."
        status=$(aws cloudfront list-distributions --query "DistributionList.Items[?starts_with(Id, '$id')]" --output text)
    done
    echo ""
    echo "completed for delete cloudfront-distributions"    
done 

echo deleting cloudfront-origin-access-controls
for id in $(aws cloudfront list-origin-access-controls --query "OriginAccessControlList.Items[?starts_with(Name, '$prefix_id')].Id" --output text); do
    if [ "$id" == "None" ]; then
        break
    fi
    echo "  $id"
    aws cloudfront delete-origin-access-control --id "$id" --if-match $(aws cloudfront get-origin-access-control --id "$id" | jq -r .ETag)
done 

echo deleting wafv2-web-acls
for id in $(aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1 --query "WebACLs[?starts_with(Name, '$prefix_id')].Id" --output text); do
    if [ "$id" == "None" ]; then
        break
    fi
    echo "  $id"
    aws wafv2 list-web-acls  --scope CLOUDFRONT --region us-east-1 --query "WebACLs[?starts_with(Id, '$id')]" | jq .[0] > web-acl.json
    aws wafv2 delete-web-acl --scope CLOUDFRONT --region us-east-1 --id $(cat web-acl.json | jq -r .Id) --lock-token $(cat web-acl.json | jq -r .LockToken) --name $(cat web-acl.json | jq -r .Name) 
    rm web-acl.json
done 

echo deleting wafv2-ip-sets
for id in $(aws wafv2 list-ip-sets --scope CLOUDFRONT --region us-east-1 --query "IPSets[?starts_with(Name, '$prefix_id')].Id" --output text); do
    echo "  $id"
    
    aws wafv2 list-ip-sets  --scope CLOUDFRONT --region us-east-1 --query "IPSets[?starts_with(Id, '$id')]" | jq .[0] > ip-set.json
    aws wafv2 delete-ip-set --scope CLOUDFRONT --region us-east-1 --id $(cat ip-set.json | jq -r .Id) --lock-token $(cat ip-set.json | jq -r .LockToken) --name $(cat ip-set.json | jq -r .Name) 
    rm ip-set.json
done 

echo deleting rest-apis
for id in $(aws apigateway get-rest-apis --query "items[?starts_with(name, '$prefix_id')].id" --output text); do
    echo "  $id"
    aws apigateway delete-rest-api --rest-api-id "$id"
done 

echo deleting auto-scaling-groups
for id in $(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?starts_with(AutoScalingGroupName, '$prefix_id')].AutoScalingGroupName" --output text); do
    echo "  $id"
    aws autoscaling suspend-processes --auto-scaling-group-name "$id"
    aws autoscaling delete-auto-scaling-group --force-delete --auto-scaling-group-name "$id" 
done

echo deleting load-balancers
for id in $(aws elbv2 describe-load-balancers --query "LoadBalancers[?starts_with(LoadBalancerName, '$prefix_id')].LoadBalancerArn" --output text); do
    echo "  $id"
    aws elbv2 delete-load-balancer --load-balancer-arn "$id"
done

echo deleting target-groups
for id in $(aws elbv2 describe-target-groups --query "TargetGroups[?starts_with(TargetGroupName, '$prefix_id')].TargetGroupArn" --output text); do
    echo "  $id"
    aws elbv2 delete-target-group --target-group-arn "$id"
done

echo deleting user-pools
for id in $(aws cognito-idp list-user-pools --max-results 10 --query "UserPools[?starts_with(Name, '$prefix_id')].Id" --output text); do
    aws cognito-idp delete-user-pool --user-pool-id "$id"
done

echo deleting identity-pools
for id in $(aws cognito-identity list-identity-pools --max-results 10 --query "IdentityPools[?starts_with(IdentityPoolName, '$prefix_id')].IdentityPoolId" --output text); do
    echo "  $id"
    aws cognito-identity delete-identity-pool --identity-pool-id "$id"
done

echo deleting cloudwatch-rule
for id in $(aws events list-rules --name-prefix "$prefix_id" --query "Rules[].Name" --output text); do
    echo "  $id"
    for id1 in $(aws events list-targets-by-rule --rule "$id" --query "Targets[].Id" --output text); do
        echo "   target $id1"
        aws events remove-targets --rule "$id" --ids "$id1" > /dev/null
    done 
    aws events delete-rule --name "$id"
done 

echo deleting functions
for id in $(aws lambda list-functions  --query "Functions[?starts_with(FunctionName, '$prefix_id')].FunctionName" --output text); do
    echo "  $id"
    aws lambda update-function-configuration --function-name "$id" --vpc-config SubnetIds=[],SecurityGroupIds=[] > /dev/null
    aws lambda delete-function               --function-name "$id"
done

echo deleting dynamodb-tables 
for id in $(aws dynamodb list-tables  --query "TableNames[?starts_with(@, '$prefix_id')]" --output text); do
    echo "  $id"
    aws dynamodb delete-table --table-name "$id"
done

echo deleting roles
for id in $(aws iam list-roles  --query "Roles[?starts_with(RoleName, '$prefix_id')].RoleName" --output text); do
    echo "  role $id"
    for id1 in $(aws iam list-role-policies --role-name "$id" --query "PolicyNames" --output text); do
        echo "   role policy $id1"
        aws iam delete-role-policy --role-name "$id" --policy-name "$id1"
    done  
  
    for id1 in $(aws iam list-attached-role-policies --role-name "$id" --query "AttachedPolicies[].PolicyArn" --output text); do
        echo "   detach role policy $id1"
        aws iam detach-role-policy --role-name "$id" --policy-arn "$id1"
    done

    for id1 in $(aws iam list-instance-profiles-for-role --role-name "$id" --query "InstanceProfiles[?starts_with(InstanceProfileName, '$prefix_id')].InstanceProfileName" --output text); do
        echo "   remove role policy $id1"
        aws iam remove-role-from-instance-profile --role-name "$id" --instance-profile-name "$id1"
    done  
    
    aws iam delete-role --role-name "$id"
done

echo deleting policies
for id in $(aws iam list-policies  --query "Policies[?starts_with(PolicyName, '$prefix_id')].Arn" --output text); do
    echo "  $id"
    aws iam delete-policy --policy-arn "$id"
done

for id in $(aws iam list-instance-profiles --query "InstanceProfiles[?starts_with(InstanceProfileName, '$prefix_id')].InstanceProfileName" --output text); do
    echo "  $id"
    aws iam delete-instance-profile --instance-profile-name "$id"
done 

echo deleting imagebuilder-pipeline
for id in $(aws imagebuilder list-image-pipelines --query "imagePipelineList[?starts_with(name, '$prefix_id')].arn" --output text); do
    echo "  $id"
    aws imagebuilder delete-image-pipeline --image-pipeline-arn "$id" > /dev/null
done

echo deleting imagebuilder-recipes
for id in $(aws imagebuilder list-image-recipes --query "imageRecipeSummaryList[?starts_with(name, '$prefix_id')].arn" --output text); do
    echo "  $id"
    aws imagebuilder delete-image-recipe --image-recipe-arn "$id" > /dev/null
done

echo deleting imagebuilder-components
for id in $(aws imagebuilder list-components --query "componentVersionList[?starts_with(name, '$prefix_id')].arn" --output text); do
    echo "  $id"
    for id1 in $(aws imagebuilder list-component-build-versions --component-version-arn "$id"   --query "componentSummaryList[].arn" --output text); do
        echo "  $id1"
        aws imagebuilder delete-component --component-build-version-arn "$id1" > /dev/null > /dev/null
    done    
done

echo deleting imagebuilder-infrastructure-configurations
for id in $(aws imagebuilder list-infrastructure-configurations --query "infrastructureConfigurationSummaryList[?starts_with(name, '$prefix_id')].arn" --output text); do
    echo "  $id"
    aws imagebuilder delete-infrastructure-configuration --infrastructure-configuration-arn "$id" > /dev/null
done

echo deleting imagebuilder-distribution-configurations
for id in $(aws imagebuilder list-distribution-configurations --query "distributionConfigurationSummaryList[?starts_with(name, '$prefix_id')].arn" --output text); do
    echo "  $id"
    aws imagebuilder delete-distribution-configuration --distribution-configuration-arn "$id" > /dev/null
done

echo deleting imagebuilder-images 
for image_arn in $(aws imagebuilder list-images --query "imageVersionList[?starts_with(arn, 'arn:aws:imagebuilder:$region:$account_id:image/$prefix_id')].arn" --output text); do
    echo "  $image_arn"
    for image_version_arn in $(aws imagebuilder list-image-build-versions --image-version-arn "$image_arn"   --query "imageSummaryList[].arn" --output text); do
        echo "      $image_version_arn"
        aws imagebuilder delete-image --image-build-version-arn  "$image_version_arn" > /dev/null
    done
done

echo deleting ssm-documents 
for id in $(aws ssm list-documents --filters Key=Owner,Values=Self --query "DocumentIdentifiers[?starts_with(Name, '$prefix_id')].Name" --output text); do
    echo "  $id"
    aws ssm delete-document --name "$id"
done

echo deleting ssm-parameters 
for id in $(aws ssm describe-parameters --query "Parameters[?starts_with(Name, '/$prefix_id')].Name" --output text); do
    echo "  $id"
    aws ssm delete-parameter --name "$id"
done

echo deleting log-groups
for id in $(aws logs describe-log-groups --query "logGroups[?contains(logGroupName, '/$prefix_id')].logGroupName" --output text); do
    echo "  $id"
    aws logs delete-log-group --log-group-name "$id"
done 

echo deleting s3-buckets
for id in $(aws s3api list-buckets --query "Buckets[?contains(Name, '$prefix_id')].Name" --output text); do
    echo "  $id"
    aws s3 rm "s3://$id" --recursive
    aws s3 rb "s3://$id"
done 

echo deleting ec2-launch-templates
for id in $(aws ec2 describe-launch-templates --query "LaunchTemplates[?starts_with(LaunchTemplateName, '$prefix_id')].LaunchTemplateName" --output text); do
    echo "  $id"
    aws ec2 delete-launch-template --launch-template-name "$id" > /dev/null
done 

echo deleting ec2-ami-images
for id in $(aws ec2 describe-images --owners $account_id --query "Images[?starts_with(ImageLocation, '$account_id/$prefix_id')].ImageId" --output text); do
    echo "  $id"
    aws ec2 deregister-image --image-id "$id"
done

echo deleting ec2-vpce
for id in $(aws ec2 describe-vpc-endpoints --query "VpcEndpoints[].{Tags:Tags, Id: VpcEndpointId}" | jq "map(select(.Tags[] | select(.Key==\"Name\") | .Value | startswith(\"$prefix\")))[].Id" -r); do
    echo "  $id"
    aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$id"

    echo -n "    waiting for deleting ec2-vpce $id"
    status=$(aws ec2 describe-vpc-endpoints --query "VpcEndpoints[?VpcEndpointId=='$id'].State" --output text)
    while [ "$status" != "" ]; do 
        sleep 2s
        echo -n "."
        status=$(aws ec2 describe-vpc-endpoints --query "VpcEndpoints[?VpcEndpointId=='$id']" --output text)
    done
    echo ""
    echo "completed for deleting ec2-vpce $id"
done

echo deleting ec2-nat
for id in $(aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=$prefix_id" --query "NatGateways[].NatGatewayId" --output text); do
    echo "  $id"
    aws ec2 delete-nat-gateways --nat-gateway-id "$id"

    echo -n "waiting for deleting ec2-nat"
    status=$(aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=$prefix_id" --query "NatGateways[].State" --output text)
    while [ $status != "deleted" ]; do 
        sleep 2s
        echo -n "."
        status=$(aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=$prefix_id" --query "NatGateways[].State" --output text)
    done
    echo ""
    echo "completed for deleting ec2-nat"
done

echo deleting ec2-security-groups-rules
for id in $(aws ec2 describe-security-groups --query "SecurityGroups[?contains(GroupName, '$prefix_id')].GroupId" --output text); do
    echo "  $id"

      json_ingress=`aws ec2 describe-security-groups --group-id "$id" --query "SecurityGroups[0].IpPermissions"`
      json_egress=`aws ec2 describe-security-groups  --group-id "$id" --query "SecurityGroups[0].IpPermissionsEgress"`
      
      if [ "$json_ingress" != "[]" ]; then
          aws ec2 revoke-security-group-ingress --cli-input-json "{\"GroupId\": \"$id\", \"IpPermissions\": $json_ingress}" > /dev/null
      else
          echo "    no ingress rules found to be destroyed in group_name $group_name / group_id $id."
      fi
      
      if [ "$json_egress" != "[]" ]; then
          aws ec2 revoke-security-group-egress --cli-input-json "{\"GroupId\": \"$id\", \"IpPermissions\": $json_egress}" > /dev/null
      else
          echo "    no egress rules found to be destroyed in group_name $group_name / group_id $id."
      fi

    aws ec2 delete-security-group --group-id $id
done 
# run it twice in case you have dependencies
for id in $(aws ec2 describe-security-groups --query "SecurityGroups[?contains(GroupName, '$prefix_id')].GroupId" --output text); do
    echo "  $id"
    aws ec2 delete-security-group --group-id $id
done

echo deleting kms-key 
for id in $(aws kms list-aliases --query "Aliases[?starts_with(AliasName, 'alias/$prefix_id')].TargetKeyId" --output text); do
    echo "  $id"
    aws kms schedule-key-deletion --key-id "$id" > /dev/null
done

echo deleting kms-key-alias 
for id in $(aws kms list-aliases --query "Aliases[?starts_with(AliasName, 'alias/$prefix_id')].AliasName" --output text); do
    echo "  $id"
    aws kms delete-alias --alias-name "$id"
done