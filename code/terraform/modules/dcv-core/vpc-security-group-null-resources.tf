# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# Deleting ingress / egress rules before removing the security group to allow proper destroy to happen
resource "null_resource" "on_destroy_sg" {
  depends_on  = [
    local.vpc_security_groups
  ]
  for_each = local.vpc_security_groups
  
  triggers = {
    region     = var.env.region
    vpc_id     = var.module_network.vpc.id
    group_name = each.value.name
  }
  # requried to link it with resource and allow destroy
  provisioner "local-exec" {
    when = create
    on_failure = continue
    command = <<-EOT
      group_name=${self.triggers.group_name}
    EOT
  }
  
  provisioner "local-exec" {
    when = destroy
    on_failure = continue
    command = <<-EOT
      region=${self.triggers.region}
      vpc_id=${self.triggers.vpc_id}
      group_name=${self.triggers.group_name}
      
      group_id=$(aws ec2 describe-security-groups \
        --region $region \
        --filters "Name=group-name,Values=$group_name" "Name=vpc-id,Values=$vpc_id" \
        --query "SecurityGroups[0].GroupId" \
        --output text)
      
      json_ingress=`aws ec2 describe-security-groups --region $region --group-id $group_id --query "SecurityGroups[0].IpPermissions"`
      json_egress=`aws ec2 describe-security-groups --region $region --group-id $group_id --query "SecurityGroups[0].IpPermissionsEgress"`
      
      if [ "$json_ingress" != "[]" ]; then
          aws ec2 revoke-security-group-ingress --region $region --cli-input-json "{\"GroupId\": \"$group_id\", \"IpPermissions\": $json_ingress}"
      else
          echo "no ingress rules found to be destroyed in group_name $group_name / group_id $group_id."
      fi
      
      if [ "$json_egress" != "[]" ]; then
          aws ec2 revoke-security-group-egress --region $region --cli-input-json "{\"GroupId\": \"$group_id\", \"IpPermissions\": $json_egress}"
      else
          echo "no egress rules found to be destroyed in group_name $group_name / group_id $group_id."
      fi
    EOT
  }
}
