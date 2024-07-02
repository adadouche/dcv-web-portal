# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
module "encryption" {
  source     = "../../modules/core-encryption"
  env        = local.env
}

module "network" {
  source     = "../../modules/core-network"
  env        = local.env

  config     = local.network_config
  
  module_encryption = module.encryption

  depends_on  = [
    module.encryption
  ]
}

module "authentication" {
  source     = "../../modules/core-authentication"
  env        = local.env

  config     = local.authentication_config
  
  module_encryption = module.encryption

  depends_on  = [
    module.encryption
  ]  
}
