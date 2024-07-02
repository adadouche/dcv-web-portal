# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

data "aws_iam_policy_document" "policy_document" {
  statement {
    sid = "Enable IAM User Permissions"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.env.account_id}:root"]
    }

    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = ["*"] # root has all permissions on the kms key
  }

  statement {
    sid = "Allow cloudwatch to (d)encrypt with this key"
    principals {
      type        = "Service"
      identifiers = ["logs.${var.env.region}.amazonaws.com"]
    }
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${var.env.region}:${var.env.account_id}:*"]
    }

    resources = ["*"]
  }

  statement {
    sid = "Allow ASG to start instances with EBS volumes encrypted with this key"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.env.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      ]
    }

    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
  }

  statement {
    sid = "Allow attachment of persistent resources"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.env.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      ]
    }

    effect = "Allow"
    actions = [
      "kms:CreateGrant"
    ]
    resources = ["*"]
    condition {
      test     = "Bool"
      values   = [true]
      variable = "kms:GrantIsForAWSResource"
    }
  }

  statement {
    sid = "Allow Cloudwatch to write logs encrypted with this key"

    principals {
      identifiers = ["logs.amazonaws.com", "delivery.logs.amazonaws.com"]
      type        = "Service"
    }

    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
  }
}
