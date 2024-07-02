# # Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# # SPDX-License-Identifier: MIT-0

# module "lambda_cognito_proxy_idp" {
#   source     = "./lambdas/cognito-proxy-idp"
#   env        = var.env

#   module_encryption     = var.module_encryption
#   config = {
#     user_pool = var.module_authentication.user_pool
#     secret    = var.module_authentication.user_pool_client_secret
#   }
# }

# module "lambda_cognito_proxy_identity" {
#   source     = "./lambdas/cognito-proxy-identity"
#   env        = var.env

#   module_encryption     = var.module_encryption
#   config = {
#     user_pool = var.module_authentication.user_pool
#   }
# }
