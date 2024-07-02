# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# https://www.terraform.io/docs/providers/aws/r/cognito_identity_pool_roles_attachment.html


resource "aws_iam_role" "identity_pool_authenticated" {
  name = "${var.env.prefix}-authenticated"

  assume_role_policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "cognito-identity.amazonaws.com"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.identity_pool.id}"
            },
            "ForAnyValue:StringLike": {
              "cognito-identity.amazonaws.com:amr": "authenticated"
            }
          }
        }
      ]
    }
  )
}

# resource "aws_iam_role" "identity_pool_authenticated_proxy" {
#   name = "${var.env.prefix}-authenticated-proxy"

#   assume_role_policy = jsonencode(
#     {
#       "Version": "2012-10-17",
#       "Statement": [
#         {
#           "Effect": "Allow",
#           "Principal": {
#             "Federated": "cognito-identity.amazonaws.com"
#           },
#           "Action": "sts:AssumeRoleWithWebIdentity",
#           "Condition": {
#             "StringEquals": {
#               "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.identity_pool_proxy.id}"
#             },
#             "ForAnyValue:StringLike": {
#               "cognito-identity.amazonaws.com:amr": "authenticated"
#             }
#           }
#         }
#       ]
#     }
#   )
# }

resource "aws_iam_role" "identity_pool_unauthenticated" {
  name = "${var.env.prefix}-unauthenticated"

  assume_role_policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "cognito-identity.amazonaws.com"
          },
          "Action": "sts:AssumeRole",
          "Condition": {
            "Bool": {
              "aws:MultiFactorAuthPresent": "true"
            }
          }
        }
      ]
    }
  )
}
# we can then attach additional policies to each identity pool role

resource "aws_iam_role_policy" "identity_pool_authenticated" {
  name = "${var.env.prefix}-authenticated-policy"
  role = aws_iam_role.identity_pool_authenticated.id

  policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "cognito-sync:*",
          ],
          "Resource": [
            "arn:aws:cognito-sync:${var.env.region}:${var.env.account_id}:*"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "cognito-identity:*"
          ],
          "Resource": [
            "arn:aws:cognito-identity:${var.env.region}:${var.env.account_id}:*"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          "Resource": [
            "arn:aws:kms:${var.env.region}:${var.env.account_id}:key/${var.module_encryption.kms_key.id}"
          ]
        }
      ]
    }
    )
}

# resource "aws_iam_role_policy" "identity_pool_authenticated_proxy" {
#   name = "${var.env.prefix}-authenticated-proxy-policy"
#   role = aws_iam_role.identity_pool_authenticated_proxy.id

#   policy = jsonencode(
#     {
#       "Version": "2012-10-17",
#       "Statement": [
#         {
#           "Effect": "Allow",
#           "Action": [
#             "cognito-sync:*",
#           ],
#           "Resource": [
#             "arn:aws:cognito-sync:${var.env.region}:${var.env.account_id}:*"
#           ]
#         },
#         {
#           "Effect": "Allow",
#           "Action": [
#             "cognito-identity:*"
#           ],
#           "Resource": [
#             "arn:aws:cognito-identity:${var.env.region}:${var.env.account_id}:*"
#           ]
#         },
#         {
#           "Effect": "Allow",
#           "Action": [
#             "kms:Encrypt",
#             "kms:Decrypt",
#             "kms:ReEncrypt*",
#             "kms:GenerateDataKey*",
#             "kms:DescribeKey"
#           ],
#           "Resource": [
#             "arn:aws:kms:${var.env.region}:${var.env.account_id}:key/${var.module_encryption.kms_key.id}"
#           ]
#         }
#       ]
#     }
#   )
# }

# we don't allow unauthenticated access, so just set all actions to be denied
resource "aws_iam_role_policy" "apps_identity_pool_unauthenticated" {
  name = "${var.env.prefix}-unauthenticated-policy"
  role = aws_iam_role.identity_pool_unauthenticated.id

  policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Deny",
          "Action": [
            "*"
          ],
          "Resource": [
            "*"
          ]
        }
      ]
    }
  )
}
