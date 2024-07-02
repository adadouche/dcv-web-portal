# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

module "health_check_resource" {
  source     = "../common/api-gateway/resource"
  env        = var.env
  
  resource_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  resource_parent    = aws_api_gateway_rest_api.api_gateway_rest_api.root_resource_id
  resource_path_part = "health-check"
}

module "health_check_method" {
  source     = "../common/api-gateway/method/mock-get"
  env        = var.env
  
  method_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  method_resource  = module.health_check_resource.api_gateway_resource

  depends_on = [
    module.health_check_resource,
  ]
}