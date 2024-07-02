# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  function_name   = basename(abspath(path.module))
  function_config = {
    environment = {
      variables = {
        DCV_SERVER_TCP_PORT = var.config.dcv_server_tcp_port
        DCV_SERVER_UDP_PORT = var.config.dcv_server_udp_port
      }
    }
  }
}

module "lambda" {
  source     = "../../../common/lambda"
  env        = var.env
  
  function_name   = local.function_name
  function_path   = "${abspath(path.module)}"
  function_config = local.function_config
  function_role   = aws_iam_role.function_role.arn
}