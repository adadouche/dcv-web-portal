# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_cognito_user_group" "user_group_admin" {
  name         = var.config.admin_group_name
  user_pool_id = aws_cognito_user_pool.user_pool.id
  description  = "Administrators group"
  precedence   = 1
}