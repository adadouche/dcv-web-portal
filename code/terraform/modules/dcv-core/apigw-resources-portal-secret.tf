# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  portal_secret_resources_names = {
    "get" : "portal-secret-get",
  }
}

module "portal_secret_resource" {
  source     = "../common/api-gateway/resource"
  env        = var.env
  
  resource_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  resource_parent    = module.portal_resource.api_gateway_resource.id
  resource_path_part = "secret"
}

module "portal_secret_options" {
  source     = "../common/api-gateway/method/mock-options"
  env        = var.env
  
  method_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  method_resource  = module.portal_secret_resource.api_gateway_resource
}

module "portal_secret_get_resource" {
  source     = "../common/api-gateway/resource"
  env        = var.env
  
  resource_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  resource_parent    = module.portal_secret_resource.api_gateway_resource.id
  resource_path_part = "get"
}

module "portal_secret_get" {
  source     = "../common/api-gateway/method/lambda-get"
  env        = var.env
  
  method_rest_api      = aws_api_gateway_rest_api.api_gateway_rest_api
  method_resource      = module.portal_secret_get_resource.api_gateway_resource
  method_authorization = local.method_authorization_cognito
  method_authorizer    = local.method_authorizer_cognito
  lambda_module        = local.lambdas["portal-secret-get"]
}

resource "aws_lambda_permission" "portal_secret_get" {
  statement_id  = "AllowExecutionFromAPIGateway-${local.lambdas["portal-secret-get"].lambda.function_name}"
  action        = "lambda:InvokeFunction"
  function_name =  local.lambdas["portal-secret-get"].lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway_rest_api.execution_arn}/*"
}
