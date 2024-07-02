# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

module "lambda_cognito_post_authentication" {
  source     = "./lambdas/cognito-post-authentication"
  env        = var.env

  module_encryption = var.module_encryption
}

resource "aws_lambda_permission" "lambda_permission_post_authentication" {
  statement_id  = "allow-cognito-post-authentication"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_cognito_post_authentication.lambda.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.user_pool.arn
}

locals {
  lambdas = {
    "cognito-post-authentication" = module.lambda_cognito_post_authentication.lambda
  }
}
