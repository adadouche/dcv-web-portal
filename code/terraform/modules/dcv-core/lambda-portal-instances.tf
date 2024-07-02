# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

module "lambda_instances_hibernate" {
  source     = "./lambdas/portal-instances-hibernate"
  env        = var.env

  module_encryption     = var.module_encryption
  module_authentication = var.module_authentication
}

module "lambda_instances_list" {
  source     = "./lambdas/portal-instances-list"
  env        = var.env

  module_encryption     = var.module_encryption
  module_authentication = var.module_authentication
}

module "lambda_instances_reboot" {
  source     = "./lambdas/portal-instances-reboot"
  env        = var.env
  
  module_encryption     = var.module_encryption
  module_authentication = var.module_authentication
}

module "lambda_instances_start" {
  source     = "./lambdas/portal-instances-start"
  env        = var.env
  
  module_encryption     = var.module_encryption
  module_authentication = var.module_authentication
}

module "lambda_instances_stop" {
  source     = "./lambdas/portal-instances-stop"
  env        = var.env
  
  module_encryption     = var.module_encryption
  module_authentication = var.module_authentication
}

module "lambda_instances_terminate" {
  source     = "./lambdas/portal-instances-terminate"
  env        = var.env
  
  module_encryption     = var.module_encryption
  module_authentication = var.module_authentication
}