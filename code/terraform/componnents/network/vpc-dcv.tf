# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_vpc" "vpc" {
  cidr_block           = var.config.dcv.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name" = "${local.env.prefix}-dcv"
  }
  
}

/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "igw" {
  count  = (var.config.deployment_mode == "public" ? 1 : 0)
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "${local.env.prefix}-dcv-igw"
  }  
}

# /* Elastic IP for NAT */
resource "aws_eip" "nat_eip" {
  count  = (var.config.deployment_mode == "public" ? var.config.dcv.subnets_az_count : 0)
  domain = "vpc"
  tags = {
    "Name" = "${local.env.prefix}-dcv-nat-eip-${count.index}"
  }   
}

resource "aws_nat_gateway" "nat" {
  count         = (var.config.deployment_mode == "public" ? var.config.dcv.subnets_az_count : 0)
  allocation_id = element(aws_eip.nat_eip.*.id, count.index)
  subnet_id     = element(aws_subnet.subnet_public.*.id, count.index)
  connectivity_type  ="public"
  tags = {
    "Name" = "${local.env.prefix}-dcv-nat-${count.index}"
  }
}

resource "aws_route_table" "public" {
  count  = (var.config.deployment_mode == "public" ? var.config.dcv.subnets_az_count : 0)
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" : "${local.env.prefix}-dcv-rtb-public-${count.index}"
  }
}

resource "aws_route" "public" {
  count                  = (var.config.deployment_mode == "public" ? var.config.dcv.subnets_az_count : 0)
  route_table_id         = element(aws_route_table.public.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
}

resource "aws_route_table" "private" {
  count  = var.config.dcv.subnets_az_count
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" : "${local.env.prefix}-dcv-rtb-private-${count.index}"
  }
}

resource "aws_route" "private" {
  count                  = (var.config.deployment_mode == "public" ? var.config.dcv.subnets_az_count : 0)
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat.*.id, count.index)
}

resource "aws_subnet" "subnet_public" {
  count                   = (var.config.deployment_mode == "public" ? var.config.dcv.subnets_az_count : 0)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(local.subnet_cidr_block_public, count.index)
  availability_zone       = element(local.az_names                , count.index)
  
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${local.env.prefix}-dcv-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "subnet_private" {
  count                   = var.config.dcv.subnets_az_count
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(local.subnet_cidr_block_private, count.index)
  availability_zone       = element(local.az_names                 , count.index)
  
  map_public_ip_on_launch = false

  tags = {
    "Name" = "${local.env.prefix}-dcv-private-subnet-${count.index}"
  }
}

resource "aws_route_table_association" "public" {
  count          = (var.config.deployment_mode == "public" ? var.config.dcv.subnets_az_count : 0)
  subnet_id      = element(aws_subnet.subnet_public.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count          = var.config.dcv.subnets_az_count  
  subnet_id      = element(aws_subnet.subnet_private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}