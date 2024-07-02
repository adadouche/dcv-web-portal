# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  portal_dcv_resources_names = {
    "configure"   : "nice-dcv-server-configure",
  }
}

module "portal_dcv_resource" {
  source     = "../common/api-gateway/resource"
  env        = var.env
  
  resource_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  resource_parent    = module.portal_resource.api_gateway_resource.id
  resource_path_part = "dcv"
}

module "portal_dcv_options" {
  source     = "../common/api-gateway/method/mock-options"
  env        = var.env
  
  method_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  method_resource  = module.portal_dcv_resource.api_gateway_resource
}

module "portal_dcv_function_resource" {
  for_each   = { for resources_name, function_name in local.portal_dcv_resources_names: resources_name => function_name }
  source     = "../common/api-gateway/resource"
  env        = var.env
  
  resource_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  resource_parent    = module.portal_dcv_resource.api_gateway_resource.id
  resource_path_part = each.key
}

module "portal_dcv_function_post" {
  for_each   = { for resources_name, function_name in local.portal_dcv_resources_names: resources_name => function_name }
  source     = "../common/api-gateway/method/lambda-post"
  env        = var.env
  
  method_rest_api      = aws_api_gateway_rest_api.api_gateway_rest_api
  method_resource      = module.portal_dcv_function_resource[each.key].api_gateway_resource
  method_authorization = local.method_authorization_cognito
  method_authorizer    = local.method_authorizer_cognito
  lambda_module        = local.lambdas[each.value]
}

resource "aws_lambda_permission" "lambda_permission_function_dcv_post" {
  for_each   = { for resources_name, function_name in local.portal_dcv_resources_names: resources_name => function_name }
  statement_id  = "AllowExecutionFromAPIGateway-${local.lambdas[each.value].lambda.function_name}"
  action        = "lambda:InvokeFunction"
  function_name =  local.lambdas[each.value].lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway_rest_api.execution_arn}/*"
}