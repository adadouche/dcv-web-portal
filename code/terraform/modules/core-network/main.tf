# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  use_existing_vpcs = lookup(var.config , "use_existing_vpcs", false)
}

module "network_create" {
  count      = (local.use_existing_vpcs ? 0 : 1)
  source     = "./network-create"
  env        = var.env

  config     = var.config
  
  module_encryption = var.module_encryption
}

module "network_reuse" {
  count      = (local.use_existing_vpcs ? 1 : 0)
  source     = "./network-reuse"
  env        = var.env

  config     = var.config
  
  module_encryption = var.module_encryption
}
