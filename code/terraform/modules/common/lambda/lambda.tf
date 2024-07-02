# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# function triggered after user creation confirmed to create a secret in secrets manager
resource "aws_lambda_function" "lambda_function" {
  depends_on      = [
    data.archive_file.archive
  ]
  filename         = data.archive_file.archive.output_path
  source_code_hash = data.archive_file.archive.output_base64sha256
  function_name    = "${var.env.prefix}-${var.function_name}"
  role             = var.function_role
  handler          = "index.lambda_handler"
  runtime          = "python3.9"
  timeout          = 30
  architectures    = ["arm64"]
  environment {
    variables = var.function_config.environment.variables
  }
  vpc_config  {
    subnet_ids         = try(var.function_config.subnet_ids         , [])
    security_group_ids = try(var.function_config.security_group_ids , [])
  }
}

