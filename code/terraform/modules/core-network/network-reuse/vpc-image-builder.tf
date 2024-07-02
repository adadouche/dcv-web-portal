# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

data "aws_vpc" "ib_vpc" {
  id    = var.config.vpc_image_builder_existing_id
}

data "aws_subnet" "ib_subnet_public" {
  id    = var.config.vpc_image_builder_existing_public_subnet_id
}
