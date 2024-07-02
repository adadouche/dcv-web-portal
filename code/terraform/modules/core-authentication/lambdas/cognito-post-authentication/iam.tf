# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_iam_role" "function_role" {
  name               = "${var.env.prefix}-${local.function_name}-function-role"
  assume_role_policy = jsonencode(
    {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Action": "sts:AssumeRole",
         "Principal": {
           "Service": ["apigateway.amazonaws.com", "lambda.amazonaws.com"]
         },
         "Effect": "Allow",
         "Sid": ""
       }
     ]
    }
  )
}

resource "aws_iam_policy" "function_policy" {
  name = "${var.env.prefix}-${local.function_name}-function-policy"
  path = "/"

  policy = jsonencode(
    {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Action": [
           "logs:CreateLogGroup",
           "logs:CreateLogStream",
           "logs:PutLogEvents"
         ],
         "Resource": "arn:aws:logs:${var.env.region}:${var.env.account_id}:*",
         "Effect": "Allow"
       },
       {
         "Action": [
            "secretsmanager:CreateSecret",
            "secretsmanager:DescribeSecret",
            "secretsmanager:RestoreSecret",
            "secretsmanager:UpdateSecret",
            "secretsmanager:TagResource"
         ],
         "Resource": [
            "arn:aws:secretsmanager:${var.env.region}:${var.env.account_id}:secret:${var.env.prefix}-*"
          ],
         "Effect": "Allow"
       },
       {
         "Action": [
           "kms:GenerateDataKey",
           "kms:Decrypt"
         ],
         "Resource": "arn:aws:kms:${var.env.region}:${var.env.account_id}:key/${var.module_encryption.kms_key.id}",
         "Effect": "Allow"
       }
     ]
    }  
  )
}

resource "aws_iam_role_policy_attachment" "function_policy_attachment" {
  role       = aws_iam_role.function_role.name
  policy_arn = aws_iam_policy.function_policy.arn
}
