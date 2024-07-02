# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

data "aws_availability_zones" "available" {
  state = "available"
}

locals{
  availability_zones_names        = [for i in range(var.config.vpc_dcv_subnets_az_count): sort(data.aws_availability_zones.available.names)[i]]  

  subnet_cidr_block_public        = [for i in range(var.config.vpc_dcv_subnets_az_count): cidrsubnet(var.config.vpc_dcv_cidr_block, var.config.vpc_dcv_subnets_cidr_bits, i)] 
  subnet_cidr_block_private       = [for i in range(var.config.vpc_dcv_subnets_az_count): cidrsubnet(var.config.vpc_dcv_cidr_block, var.config.vpc_dcv_subnets_cidr_bits, i + var.config.vpc_dcv_subnets_az_count)] 

  subnet_cidr_block_image_builder = cidrsubnet(var.config.vpc_image_builder_cidr_block, var.config.vpc_image_builder_subnets_cidr_bits, 1)
}
