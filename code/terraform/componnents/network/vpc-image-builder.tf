# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_vpc" "ib_vpc" {
  cidr_block           = var.config.image_builder.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name" = "${local.env.prefix}-image-builder"
  }
}

/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "ib_igw" {
  vpc_id = aws_vpc.ib_vpc.id

  tags = {
    "Name" = "${local.env.prefix}-ib-igw"
  }  
}

resource "aws_route_table" "ib_public" {
  vpc_id = aws_vpc.ib_vpc.id
  tags = {
    "Name" : "${local.env.prefix}-ib-rtb-public"
  }
}

resource "aws_route" "ib_public" {
  route_table_id         = aws_route_table.ib_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ib_igw.id
}

resource "aws_subnet" "ib_subnet_public" {
  vpc_id                  = aws_vpc.ib_vpc.id
  cidr_block              = local.subnet_cidr_block_image_builder
  availability_zone       = element(local.az_names, 1)
  
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${local.env.prefix}-ib-public-subnet"
  }
}

resource "aws_route_table_association" "ib_public" {
  subnet_id      = aws_subnet.ib_subnet_public.id
  route_table_id = aws_route_table.ib_public.id
}
