# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

module "lambda_templates_list" {
  source     = "./lambdas/portal-templates-list"
  env        = var.env
  
  module_encryption     = var.module_encryption
  module_authentication = var.module_authentication

}

module "lambda_templates_launch" {
  source     = "./lambdas/portal-templates-launch"
  env        = var.env
  
  module_encryption     = var.module_encryption
  module_authentication = var.module_authentication
}
