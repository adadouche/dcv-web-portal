# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  function_name   = basename(abspath(path.module))
  function_config = {
    environment = {
      variables = {
        KMS_KEY_ID  = "arn:aws:kms:${var.env.region}:${var.env.account_id}:key/${var.module_encryption.kms_key.id}"
        PROJECT     = var.env.project
        APPLICATION = var.env.application
        ENVIRONMENT = var.env.environment
        PREFIX      = var.env.prefix
      }
    }
  }
}

module "lambda" {
  source     = "../../../common/lambda"
  env        = var.env
  
  function_name   = local.function_name
  function_path   = "${abspath(path.module)}"
  function_config = local.function_config
  function_role   = aws_iam_role.function_role.arn
}