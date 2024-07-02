# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_s3_bucket" "pipeline_logs" {
  bucket        = "${var.env.account_id}-${var.env.region}-${var.env.prefix}-ib-pipeline-logs"
  force_destroy = true
}

resource "aws_s3_bucket" "downloads" {
  bucket        = "${var.env.account_id}-${var.env.region}-${var.env.prefix}-ib-downloads"
  force_destroy = true
}