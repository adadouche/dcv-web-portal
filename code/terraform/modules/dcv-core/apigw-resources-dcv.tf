# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  dcv_resources_names = {
    "auth"           : "nice-dcv-auth",
    "resolveSession" : "nice-dcv-resolve-session"
  }
}

module "dcv_parent_resource" {
  source     = "../common/api-gateway/resource"
  env        = var.env
  
  resource_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  resource_parent    = aws_api_gateway_rest_api.api_gateway_rest_api.root_resource_id
  resource_path_part = "dcv"
}

module "dcv_resources" {
  depends_on = [
    module.dcv_parent_resource
  ]
  
  for_each   = { for resources_name, function_name in local.dcv_resources_names: resources_name => function_name }
  source     = "../common/api-gateway/resource"
  env        = var.env
  
  resource_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  resource_parent    = module.dcv_parent_resource.api_gateway_resource.id
  resource_path_part = each.key
}

module "dcv_methods" {
  depends_on = [
    module.dcv_resources
  ]
  
  for_each   = { for resources_name, function_name in local.dcv_resources_names: resources_name => function_name }
  source     = "../common/api-gateway/method/lambda-any"
  env        = var.env
  
  method_rest_api      = aws_api_gateway_rest_api.api_gateway_rest_api
  method_resource      = module.dcv_resources[each.key].api_gateway_resource
  method_authorization = local.method_authorization_none
  method_authorizer    = local.method_authorizer_none  
  lambda_module        = local.lambdas[each.value]
}

resource "aws_lambda_permission" "dcv_permission" {
  for_each   = { for resources_name, function_name in local.dcv_resources_names: resources_name => function_name }
  statement_id  = "AllowExecutionFromAPIGateway-${each.value}"
  action        = "lambda:InvokeFunction"
  function_name = local.lambdas[each.value].lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway_rest_api.execution_arn}/*"  
}