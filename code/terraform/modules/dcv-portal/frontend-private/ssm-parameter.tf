# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_ssm_parameter" "proxy_api_endpoint" {
  name      = "/${var.env.prefix}/proxy-api-endpoint"
  type      = "String"
  value     = "${var.config.api_endpoint}"
}

resource "aws_ssm_parameter" "proxy_web_content_bucket" {
  name      = "/${var.env.prefix}/proxy-web-content-bucket"
  type      = "String"
  value     = "${var.config.web_content_bucket_id}"
}

