# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [ aws.current , aws.us-east-1]
    }
  }
}

locals {
  origin_id_s3   = "${var.env.prefix}-frontend-origin-s3"
  origin_id_api  = "${var.env.prefix}-frontend-origin-apigw"
}

