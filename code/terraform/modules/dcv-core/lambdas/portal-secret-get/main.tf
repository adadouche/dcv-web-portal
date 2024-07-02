# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  function_name   = basename(abspath(path.module))
  function_config = {
    environment = {
      variables = {
        PREFIX      = var.env.prefix
        PROJECT     = var.env.project
        APPLICATION = var.env.application
        ENVIRONMENT = var.env.environment
        ADMIN_GROUP_NAME = var.module_authentication.config.admin_group_name
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