# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  policy_vars = {
    project     = var.env.project
    application = var.env.application
    environment = var.env.environment
    prefix      = var.env.prefix
    account_id  = var.env.account_id
    region      = var.env.region
  }

  policy_document = templatefile( "${abspath(path.module)}/policy/policy.json", local.policy_vars )
}

resource "aws_kms_key" "key" {
  description         = "${var.env.prefix}-key"
  policy              = data.aws_iam_policy_document.policy_document.json
  # policy              = local.policy_document

  enable_key_rotation = true
  # lifecycle {
  #   prevent_destroy = false
  # }
}

resource "aws_kms_alias" "alias" {
  name          = "alias/${var.env.prefix}-key"
  target_key_id = aws_kms_key.key.key_id
  # lifecycle {
  #   prevent_destroy = false
  # }  
}