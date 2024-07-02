# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

output "config" {
  value = var.config
}

######################################################################

output "user_pool" {
  value = aws_cognito_user_pool.user_pool
}

output "user_pool_client" {
  value = aws_cognito_user_pool_client.user_pool_client
}

output "identity_pool" {
  value = aws_cognito_identity_pool.identity_pool
}

output "domain" {
  value = "${var.env.project}-${var.env.environment}"
}

######################################################################

# output "user_pool_client_secret" {
#   value = aws_secretsmanager_secret.user_pool_client_secret
# }