# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  function_name   = basename(abspath(path.module))
  function_config = {
    environment = {
      variables = {
        # COGNITO_URL       = "https://cognito-idp.${var.env.region}.amazonaws.com/"
        # CLIENT_SECRET_ARN = var.module_authentication.user_pool_client_proxy_secret.arn
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