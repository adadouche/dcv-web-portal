# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_s3_bucket" "logs" {
  bucket        = "${var.env.account_id}-${var.env.region}-${var.env.prefix}-cloudfront-logs"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "AWSConsole-AccessLogs-Policy-1544636543097",
  "Statement": [
    {
      "Sid": "AWSLogDeliveryWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": ["s3:PutObject"],
      "Resource": [
        "${aws_s3_bucket.logs.arn}/*"
      ]
    },
    {
      "Sid": "AWSLogDeliveryAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": [
        "s3:GetBucketAcl",
        "s3:PutBucketAcl"
      ],
      "Resource": "${aws_s3_bucket.logs.arn}"
    }
  ]
}
EOF
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  bucket = aws_s3_bucket.logs.id
  acl    = "private"
  depends_on = [
    aws_s3_bucket_ownership_controls.logs
  ]
}
