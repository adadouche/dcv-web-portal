# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

module "dcv_portal" {
  source     = "../../modules/dcv-portal"
  env        = local.env
  
  module_encryption     = local.module_encryption
  module_network        = local.module_network
  module_dcv            = local.module_dcv
  
  providers = {
    aws.current   = aws
    aws.us-east-1 = aws.us-east-1
  }
  
  depends_on  = [
    local.module_dcv,
  ]
}