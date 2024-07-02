# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

output "config" {
  value = var.config
}

######################################################################

output "vpc" {
  value = aws_vpc.vpc
}

output "vpc_subnets_private" {
  value = aws_subnet.subnet_private
}

output "vpc_subnets_public" {
  value = aws_subnet.subnet_public
}

output "vpc_route_table_private" {
  value = aws_route_table.private
}

######################################################################

output "vpc_image_builder" {
  value = aws_vpc.ib_vpc
}

output "vpc_image_builder_subnet" {
  value = aws_subnet.ib_subnet_public
}

######################################################################
