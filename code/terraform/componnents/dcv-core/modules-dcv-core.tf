# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

module "dcv" {
  source     = "../../modules/dcv-core"
  env        = local.env
  
  config     = merge (
    local.dcv_config,
    {
      template_config_folder = "${abspath(path.module)}/config"
    }
  )

  module_network        = local.module_network
  module_encryption     = local.module_encryption
  module_authentication = local.module_authentication

  depends_on  = [
    local.module_network,
    local.module_encryption,
    local.module_authentication
  ]
}
