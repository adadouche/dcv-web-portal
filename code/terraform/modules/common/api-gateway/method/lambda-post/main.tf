# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_api_gateway_method" "method" {
  rest_api_id   = var.method_rest_api.id
  resource_id   = var.method_resource.id
  authorization = var.method_authorization
  authorizer_id = var.method_authorizer
  http_method   = "POST"
}

resource "aws_api_gateway_method_response" "method_response" {
  rest_api_id = var.method_rest_api.id
  resource_id = var.method_resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = var.method_rest_api.id
  resource_id = var.method_resource.id
  http_method = aws_api_gateway_method.method.http_method
  type        = "AWS_PROXY"
  uri         = var.lambda_module.lambda.invoke_arn
  credentials = var.lambda_module.lambda_invoke_role.arn
  integration_http_method = "POST"
}

resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = var.method_rest_api.id
  resource_id = var.method_resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.method_response.status_code

  response_templates = {
    "application/json" = "$input.json('$')"
  }
  depends_on = [
    aws_api_gateway_integration.integration
  ]
}