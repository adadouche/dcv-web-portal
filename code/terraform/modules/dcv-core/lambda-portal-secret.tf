# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

module "lambda_secret_get" {
  source     = "./lambdas/portal-secret-get"
  env        = var.env

  module_encryption     = var.module_encryption
  module_authentication = var.module_authentication
}
