# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

module "lambda_dcv_auth" {
  source     = "./lambdas/nice-dcv-auth"
  env        = var.env
   
  module_authentication = var.module_authentication
}

module "lambda_dcv_resolve_session" {
  source     = "./lambdas/nice-dcv-resolve-session"
  env        = var.env
  
  config = merge (
    {
      dcv_server_udp_port = var.config.dcv_server_config.udp_port
      dcv_server_tcp_port = var.config.dcv_server_config.tcp_port
    }
  )
}

module "lambda_dcv_server_configure" {
  source     = "./lambdas/nice-dcv-server-configure"
  env        = var.env

  module_encryption     = var.module_encryption
  module_authentication = var.module_authentication
}
