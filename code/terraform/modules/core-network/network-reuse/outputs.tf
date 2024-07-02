# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

output "config" {
  value = var.config
}

######################################################################

output "vpc" {
  value = data.aws_vpc.vpc
}

output "vpc_subnets_private" {
  value = data.aws_subnet.subnet_private
}

output "vpc_subnets_public" {
  value = data.aws_subnet.subnet_public
}

output "vpc_route_table_private" {
  value = data.aws_route_table.private
}

######################################################################

output "vpc_image_builder" {
  value = data.aws_vpc.ib_vpc
}

output "vpc_image_builder_subnet" {
  value = data.aws_subnet.ib_subnet_public
}

######################################################################
