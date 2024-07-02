# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

data "aws_vpc" "vpc" {
  id    = var.config.vpc_dcv_existing_id
}

data "aws_subnet" "subnet_public" {
  count = (var.config.deployment_mode == "public" ? length(var.config.vpc_dcv_existing_public_subnet_ids) : 0)
  id    = var.config.vpc_dcv_existing_public_subnet_ids[count.index]
}

data "aws_subnet" "subnet_private" {
  count = (length(var.config.vpc_dcv_existing_private_subnet_ids))
  id    = var.config.vpc_dcv_existing_private_subnet_ids[count.index]
}

data "aws_route_table" "private" {
  count = (length(var.config.vpc_dcv_existing_private_subnet_ids))
  subnet_id = var.config.vpc_dcv_existing_private_subnet_ids[count.index]
}
