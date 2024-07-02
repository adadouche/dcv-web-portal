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
          "Resource": "arn:aws:logs:${var.env.region}:${var.env.account_id}:log-group:/aws/lambda/${local.function_name}:log-stream:*",
          "Effect": "Allow"
        },
        {
            "Action": [
                "ec2:CreateTags",
                "ec2:RunInstances",
                "ec2:DescribeInstanceStatus",
            ]
            "Effect": "Allow"
            "Resource": [
              "arn:aws:ec2:${var.env.region}:${var.env.account_id}:*/*",
              "arn:aws:ec2:${var.env.region}::image/*"
            ],
        },
        {
            "Action": [
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeLaunchTemplateVersions",
            ]
            "Effect": "Allow"
            "Resource": [
              "*"
            ],
        },
        {
            "Action": [
              "iam:PassRole"
            ]
            "Effect": "Allow"
            "Resource": [
              "arn:aws:iam::${var.env.account_id}:role/${var.env.prefix}-*-instance-role"
            ]
        },
        {
            "Action": [
              "kms:CreateGrant",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*",
              "kms:Encrypt",
              "kms:Describe*",
              "kms:Decrypt"
            ]
            "Effect": "Allow"
            "Resource": [
              "arn:aws:kms:${var.env.region}:${var.env.account_id}:key/${var.module_encryption.kms_key.id}",
              "arn:aws:kms:${var.env.region}:${var.env.account_id}:key/*",
            ]
        },
     ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "function_policy_attachment" {
  role       = aws_iam_role.function_role.name
  policy_arn = aws_iam_policy.function_policy.arn
}

resource "aws_iam_role_policy_attachment" "vpc_access_execution" {
  role       = aws_iam_role.function_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role" "function_invoke_role" {
  name = "${var.env.prefix}-${local.function_name}-invoke-role"

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
    name = "${var.env.prefix}-lambda"

    policy = jsonencode({
      "Version" = "2012-10-17"
      "Statement" = [
        {
          "Action" = [
            "lambda:InvokeFunction",
          ]
          "Effect" = "Allow"
          "Resource" = [
            module.lambda.function.arn
          ]
        },
      ]
    })
  }
}