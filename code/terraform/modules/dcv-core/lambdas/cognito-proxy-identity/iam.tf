# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_iam_role" "function_role" {
  name               = "${var.env.prefix}-${local.function_name}-function"
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
      #  {
      #    "Action": [
      #      "secretsmanager:GetSecretValue"
      #    ],
      #    "Resource": "${var.config.secret.arn}",
      #    "Effect": "Allow"
      #  },
      #  {
      #    "Action": [
      #      "cognito-idp:AdminInitiateAuth",
      #      "cognito-idp:AdminRespondToAuthChallenge"
      #    ],
      #    "Resource": "arn:aws:cognito-idp:${var.env.region}:${var.env.account_id}:userpool/${var.config.user_pool.id}",
      #    "Effect": "Allow"
      #  },
      #  {
      #    "Action": [
      #      "kms:GenerateDataKey",
      #      "kms:Decrypt"
      #    ],
      #    "Resource": "arn:aws:kms:${var.env.region}:${var.env.account_id}:key/${var.module_encryption.kms_key.id}",
      #    "Effect": "Allow"
      #  }
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
    name               = "${var.env.prefix}-${local.function_name}-invoke"

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

