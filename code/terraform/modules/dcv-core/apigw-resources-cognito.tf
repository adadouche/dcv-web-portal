# # Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# # SPDX-License-Identifier: MIT-0

locals {
  cognito_resources_names = {
    "idp"      : "https://cognito-idp.${var.env.region}.amazonaws.com",
    "identity" : "https://cognito-identity.${var.env.region}.amazonaws.com",
  }
}

module "cognito_parent_resource" {
  source     = "../common/api-gateway/resource"
  env        = var.env
  
  resource_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  resource_parent    = aws_api_gateway_rest_api.api_gateway_rest_api.root_resource_id
  resource_path_part = "cognito"
}

module "cognito_resources" {
  depends_on = [
    module.cognito_parent_resource
  ]
  
  for_each   = { for resources_name, function_name in local.cognito_resources_names: resources_name => function_name }
  source     = "../common/api-gateway/resource"
  env        = var.env
  
  resource_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  resource_parent    = module.cognito_parent_resource.api_gateway_resource.id
  resource_path_part = each.key
}

module "cognito_methods" {
  depends_on = [
    module.cognito_resources
  ]
  
  for_each   = { for resources_name, function_name in local.cognito_resources_names: resources_name => function_name }
  source     = "../common/api-gateway/method/http-any"
  env        = var.env
  
  method_rest_api      = aws_api_gateway_rest_api.api_gateway_rest_api
  method_resource      = module.cognito_resources[each.key].api_gateway_resource
  url                  = each.value
}

module "cognito_options" {
  depends_on = [
    module.cognito_resources
  ]
  
  for_each   = { for resources_name, function_name in local.cognito_resources_names: resources_name => function_name }
  source     = "../common/api-gateway/method/mock-options"
  env        = var.env
  
  method_rest_api  = aws_api_gateway_rest_api.api_gateway_rest_api
  method_resource  = module.cognito_resources[each.key].api_gateway_resource
}

# resource "aws_lambda_permission" "cognito_permission" {
#   for_each   = { for resources_name, function_name in local.cognito_resources_names: resources_name => function_name }
#   statement_id  = "AllowExecutionFromAPIGateway-${each.value}"
#   action        = "lambda:InvokeFunction"
#   function_name = local.lambdas[each.value].lambda.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.api_gateway_rest_api.execution_arn}/*"  
# }