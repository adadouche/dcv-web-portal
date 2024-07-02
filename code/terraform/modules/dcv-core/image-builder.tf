# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  policies_inline = jsonencode({
    Version   = "2012-10-17"
    Statement = local.template_default_config["image_builder_policies_inline_statments"]
  })
}

# Define the EC2 image builder instance role (instance used to rebuild the image for new updates or at defined cadence)
# https://docs.aws.amazon.com/imagebuilder/latest/userguide/image-builder-setting-up.html#image-builder-IAM-prereq
resource "aws_iam_role" "image_builder_instance_role" {
  name = "${var.env.prefix}-image-builder-instance-role"
  path = "/"
  assume_role_policy = jsonencode(
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "sts:AssumeRole",
                "Principal": {
                   "Service": "ec2.amazonaws.com"
                },
                "Effect": "Allow",
                "Sid": ""
            }
        ]
    }  
  )
  managed_policy_arns = [ for value in local.template_default_config["image_builder_policies_managed"]: "arn:aws:iam::aws:policy/${value}" ]
  inline_policy {
    name   = "${var.env.prefix}-image-builder-policy"
    policy = local.policies_inline
  }
}

# Define the instance profile applied to EC2 builder instance
resource "aws_iam_instance_profile" "image_builder_instance_profile" {
  name = "${var.env.prefix}-image-builder-instance-profile"
  role = aws_iam_role.image_builder_instance_role.name
}
