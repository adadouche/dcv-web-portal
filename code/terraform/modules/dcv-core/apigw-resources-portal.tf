# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

module "portal_resource" {
  source     = "../common/api-gateway/resource"
  env        = var.env
  
  resource_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  resource_parent    = aws_api_gateway_rest_api.api_gateway_rest_api.root_resource_id
  resource_path_part = "portal"
}