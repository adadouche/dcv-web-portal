# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

module "portal_templates_resource" {
  source     = "../common/api-gateway/resource"
  env        = var.env
  
  resource_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  resource_parent    = module.portal_resource.api_gateway_resource.id
  resource_path_part = "templates"
}

module "portal_templates_options" {
  source     = "../common/api-gateway/method/mock-options"
  env        = var.env
  
  method_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  method_resource  = module.portal_templates_resource.api_gateway_resource
}

module "portal_templates_list_resource" {
  source     = "../common/api-gateway/resource"
  env        = var.env
  
  resource_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  resource_parent    = module.portal_templates_resource.api_gateway_resource.id
  resource_path_part = "list"
}

module "portal_templates_list_get" {
  source     = "../common/api-gateway/method/lambda-get"
  env        = var.env
  
  method_rest_api      = aws_api_gateway_rest_api.api_gateway_rest_api
  method_resource      = module.portal_templates_list_resource.api_gateway_resource
  method_authorization = local.method_authorization_cognito
  method_authorizer    = local.method_authorizer_cognito    
  lambda_module        = local.lambdas["portal-templates-list"]
}

module "portal_templates_launch_resource" {
  source     = "../common/api-gateway/resource"
  env        = var.env
  
  resource_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  resource_parent    = module.portal_templates_resource.api_gateway_resource.id
  resource_path_part = "launch"
}

module "portal_templates_launch_post" {
  source     = "../common/api-gateway/method/lambda-post"
  env        = var.env
  
  method_rest_api      = aws_api_gateway_rest_api.api_gateway_rest_api
  method_resource      = module.portal_templates_launch_resource.api_gateway_resource
  method_authorization = local.method_authorization_cognito
  method_authorizer    = local.method_authorizer_cognito    
  lambda_module        = local.lambdas["portal-templates-launch"]
}

resource "aws_lambda_permission" "portal_templates_list_get" {
  statement_id  = "AllowExecutionFromAPIGateway-${local.lambdas["portal-templates-list"].lambda.function_name}"
  action        = "lambda:InvokeFunction"
  function_name =  local.lambdas["portal-templates-list"].lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway_rest_api.execution_arn}/*"
}

resource "aws_lambda_permission" "portal_templates_list_post" {
  statement_id  = "AllowExecutionFromAPIGateway-${local.lambdas["portal-templates-launch"].lambda.function_name}"
  action        = "lambda:InvokeFunction"
  function_name =  local.lambdas["portal-templates-launch"].lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway_rest_api.execution_arn}/*"
}