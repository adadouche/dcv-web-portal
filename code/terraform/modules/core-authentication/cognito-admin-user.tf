# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  admin_user_defined = (var.config.admin_user != null ? true : false)
}

resource "aws_cognito_user" "admin_user" {
  depends_on   = [
    aws_lambda_permission.lambda_permission_post_authentication
  ]
  count        = (local.admin_user_defined ? 1 : 0)
  user_pool_id = aws_cognito_user_pool.user_pool.id
  username     = var.config.admin_user.admin_login

  attributes = {
    email          = var.config.admin_user.admin_email
    email_verified = true
    name           = var.config.admin_user.admin_full_name
  }
  
  temporary_password = var.config.admin_user.admin_temporary_password
}

resource "aws_cognito_user_in_group" "admin_group" {
  count        = (local.admin_user_defined ? 1 : 0)
  user_pool_id = aws_cognito_user_pool.user_pool.id
  group_name   = aws_cognito_user_group.user_group_admin.name
  username     = aws_cognito_user.admin_user[0].username
}
