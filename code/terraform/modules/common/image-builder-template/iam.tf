# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_iam_role" "instance_role" {
  name = "${var.env.prefix}-${var.config.template_name}-instance-role"
  path = "/"
  managed_policy_arns = [ for value in local.policies_managed: "arn:aws:iam::aws:policy/${value}" ]
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  # inline_policy {
  #   name   = "${var.config.template_name}-template"
  #   policy = local.policies_inline_template
  # }

  # inline_policy {
  #   name   = "${var.config.template_name}-default"
  #   policy = local.policies_inline_default
  # }

  dynamic inline_policy {
    for_each = ( length(local.policies_statements_template) > 0 ? [local.policies_inline_template] : [])
    content {
      name   = "${var.config.template_name}-template"
      policy = local.policies_inline_template
    }
  }

  dynamic inline_policy {
    for_each = ( length(local.policies_statements_default) > 0 ? [local.policies_inline_default] : [])
    content {
      name   = "${var.config.template_name}-default"
      policy = local.policies_inline_default
    }
  }

}

# Define the instance profile applied to EC2 builder instance
resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.env.prefix}-${var.config.template_name}-instance-profile"
  role = aws_iam_role.instance_role.name
}
