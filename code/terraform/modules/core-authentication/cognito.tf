# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# locals {
#   secret = jsonencode(
#     {
#       "client-secret":"${aws_cognito_user_pool_client.user_pool_client.client_secret}",
#       "user-pool-id": "${aws_cognito_user_pool.user_pool.id}",
#       "identity-pool-id": "${aws_cognito_identity_pool.identity_pool.id}"
#     }
#   )
# }

resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.env.prefix}-user-pool"

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
    temporary_password_validity_days = 7
  }

  # MFA configuration
  mfa_configuration = "OPTIONAL"
  software_token_mfa_configuration {
    enabled = true
  }

  # only the administrator is allowed to create user profiles
  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  lambda_config {
    post_authentication = module.lambda_cognito_post_authentication.lambda.arn
  }
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                = "${var.env.prefix}-pool-client"
  user_pool_id        = aws_cognito_user_pool.user_pool.id
  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  generate_secret = false
  
  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 1

  token_validity_units {
    refresh_token = "days"
    id_token      = "hours"
    access_token  = "hours"
  }
}

# resource "aws_cognito_user_pool_client" "user_pool_client_proxy" {
#   name                = "${var.env.prefix}-pool-client-proxy"
#   user_pool_id        = aws_cognito_user_pool.user_pool.id
#   explicit_auth_flows = [
#     "ALLOW_ADMIN_USER_PASSWORD_AUTH",
#     "ALLOW_USER_SRP_AUTH",
#     "ALLOW_REFRESH_TOKEN_AUTH"
#   ]

#   generate_secret = true
  
#   access_token_validity  = 1
#   id_token_validity      = 1
#   refresh_token_validity = 1

#   token_validity_units {
#     refresh_token = "days"
#     id_token      = "hours"
#     access_token  = "hours"
#   }
# }

resource "aws_cognito_identity_pool" "identity_pool" {
  identity_pool_name               = "${var.env.prefix}-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.user_pool_client.id
    provider_name           = aws_cognito_user_pool.user_pool.endpoint
    server_side_token_check = true
  }
}

resource "aws_cognito_identity_pool_roles_attachment" "identity_pool_roles_attachment" {
  identity_pool_id = aws_cognito_identity_pool.identity_pool.id

  roles = {
    authenticated   = aws_iam_role.identity_pool_authenticated.arn
    unauthenticated = aws_iam_role.identity_pool_unauthenticated.arn
  }
}

# resource "aws_cognito_identity_pool" "identity_pool_proxy" {
#   identity_pool_name               = "${var.env.prefix}-identity-pool-proxy"
#   allow_unauthenticated_identities = false

#   cognito_identity_providers {
#     client_id               = aws_cognito_user_pool_client.user_pool_client_proxy.id
#     provider_name           = aws_cognito_user_pool.user_pool.endpoint
#     server_side_token_check = true
#   }
# }

# resource "aws_cognito_identity_pool_roles_attachment" "identity_pool_roles_attachment_proxy" {
#   identity_pool_id = aws_cognito_identity_pool.identity_pool_proxy.id

#   roles = {
#     authenticated   = aws_iam_role.identity_pool_authenticated_proxy.arn
#     unauthenticated = aws_iam_role.identity_pool_unauthenticated.arn
#   }
# }

# resource "aws_secretsmanager_secret" "user_pool_client_secret" {
#   description = "[${var.env.prefix}] Client secret for accessing app client [${aws_cognito_user_pool_client.user_pool_client.name}] in user pool ${aws_cognito_user_pool.user_pool.name}"
#   name        = "${var.env.prefix}-pool-client-secret"
#   kms_key_id  = var.module_encryption.kms_key.id
#   recovery_window_in_days = 0 
# }

# resource "aws_secretsmanager_secret_version" "user_pool_client_secret_value" {
#   secret_id     = aws_secretsmanager_secret.user_pool_client_secret.id
#   secret_string = local.secret
# }