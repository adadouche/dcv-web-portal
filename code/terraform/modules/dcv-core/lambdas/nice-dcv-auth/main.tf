# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  function_name   = basename(abspath(path.module))
  function_config = {
    environment = {
      variables = {
        COGNITO_USER_POOL_ID = var.module_authentication.user_pool.id
        APP_CLIENT_ID        = var.module_authentication.user_pool_client.id
        AD_DOMAIN_NAME       = var.module_authentication.domain
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