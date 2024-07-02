# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  http_method = "GET"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = var.method_rest_api.id
  resource_id   = var.method_resource.id
  authorization = "NONE"
  http_method   = local.http_method
}

resource "aws_api_gateway_method_response" "method_response" {
  depends_on = [ 
    aws_api_gateway_method.method
  ]
  rest_api_id = var.method_rest_api.id
  resource_id = var.method_resource.id
  http_method = local.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Origin"      = true,
    "method.response.header.Access-Control-Allow-Credentials" = true 
  }  
}

resource "aws_api_gateway_integration" "integration" {
  depends_on = [ 
    aws_api_gateway_method_response.method_response
  ]
  rest_api_id = var.method_rest_api.id
  resource_id = var.method_resource.id
  http_method = local.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = <<EOF
{
  "statusCode": 200,
  "body" : {
    "status": "ok"
  }
}
EOF
  }
}

resource "aws_api_gateway_integration_response" "integration_response" {
  depends_on = [ 
    aws_api_gateway_integration.integration
  ]
  rest_api_id = var.method_rest_api.id
  resource_id = var.method_resource.id
  http_method = local.http_method

  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods"     = "'GET,OPTIONS,POST,PUT,DELETE'",
    "method.response.header.Access-Control-Allow-Origin"      = "'*'"
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"    
  }
  response_templates = {
    "application/json" = <<EOF
{
  "statusCode": 200,
  "body" : {
    "status": "ok"
  }
}
EOF
  }
}