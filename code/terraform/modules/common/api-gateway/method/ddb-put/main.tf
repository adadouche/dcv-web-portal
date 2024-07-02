# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_api_gateway_method" "api_gateway_method" {
  rest_api_id   = var.method_rest_api.id
  resource_id   = var.method_resource.id
  authorization = var.method_authorization
  authorizer_id = var.method_authorizer
  http_method   = "PUT"
}

resource "aws_api_gateway_method_response" "api_gateway_method_response" {
  rest_api_id = var.method_rest_api.id
  resource_id = var.method_resource.id
  http_method = aws_api_gateway_method.api_gateway_method.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "api_gateway_integration" {
  rest_api_id = var.method_rest_api.id
  resource_id = var.method_resource.id
  http_method = aws_api_gateway_method.api_gateway_method.http_method
  type        = "AWS"
  uri         = "arn:aws:apigateway:${var.env.region}:dynamodb:action/Query"
  credentials = var.api_role.arn
  request_templates       =  var.request_templates
  integration_http_method = "POST"
  passthrough_behavior    = "NEVER"
}

resource "aws_api_gateway_integration_response" "api_gateway_integration_response" {
  rest_api_id = var.method_rest_api.id
  resource_id = aws_api_gateway_integration.api_gateway_integration.resource_id
  http_method = aws_api_gateway_integration.api_gateway_integration.http_method
  status_code = aws_api_gateway_method_response.api_gateway_method_response.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT,DELETE'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  response_templates = var.response_templates
}