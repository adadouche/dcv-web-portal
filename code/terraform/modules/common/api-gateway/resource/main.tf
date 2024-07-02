# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_api_gateway_resource" "api_gateway_resource" {
  rest_api_id = var.resource_rest_api.id
  parent_id   = var.resource_parent
  path_part   = var.resource_path_part
}