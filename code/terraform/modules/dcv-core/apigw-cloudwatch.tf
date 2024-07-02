# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_cloudwatch_log_group" "cloudwatch_log_group" {
  name              = "/aws/apigateway/${var.env.prefix}/${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  kms_key_id        = "arn:aws:kms:${var.env.region}:${var.env.account_id}:key/${var.module_encryption.kms_key.id}"
  retention_in_days = 30
  
  lifecycle {
    create_before_destroy = true
  }  
}

resource "aws_iam_role" "api_gateway_account_cloudwatch" {
  name = "${var.env.prefix}-apigtw-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Action" = "sts:AssumeRole"
        "Effect" = "Allow"
        "Principal" = {
          "Service" = "apigateway.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "${var.env.prefix}-logs"

    policy = jsonencode({
      "Version" = "2012-10-17"
      "Statement" = [
        {
          "Action" = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents",
            "logs:GetLogEvents",
            "logs:FilterLogEvents"
          ]
          "Effect"   = "Allow"
          "Resource" = "arn:aws:logs:${var.env.region}:${var.env.account_id}:log-group:*"
        },
      ]
    })
  }
}
