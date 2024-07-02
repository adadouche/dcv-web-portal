# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

output "lambda" {
  value = module.lambda.function
}

output "lambda_key" {
  value = local.function_name
}

output "lambda_role" {
  value = aws_iam_role.function_role
}

output "lambda_invoke_role" {
  value = aws_iam_role.function_invoke_role
}