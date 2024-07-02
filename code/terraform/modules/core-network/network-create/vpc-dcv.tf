# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_vpc" "vpc" {
  cidr_block           = var.config.vpc_dcv_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name" = "${var.env.prefix}-vpc"
  }
}

/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "igw" {
  count  = (var.config.deployment_mode == "public" ? 1 : 0)
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "${var.env.prefix}-vpc-igw"
  }  
}

# /* Elastic IP for NAT */
resource "aws_eip" "nat_eip" {
  count  = (var.config.deployment_mode == "public" ? var.config.vpc_dcv_subnets_az_count : 0)
  domain = "vpc"
  tags = {
    "Name" = "${var.env.prefix}-vpc-nat-eip-${count.index}"
  }   
}

resource "aws_subnet" "subnet_public" {
  count  = (var.config.deployment_mode == "public" ? var.config.vpc_dcv_subnets_az_count : 0)
  vpc_id = aws_vpc.vpc.id

  cidr_block              = element(local.subnet_cidr_block_public, count.index)
  availability_zone       = element(local.availability_zones_names, count.index)
  
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.env.prefix}-vpc-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "subnet_private" {
  count  = (var.config.vpc_dcv_subnets_az_count)
  vpc_id = aws_vpc.vpc.id

  cidr_block              = element(local.subnet_cidr_block_private, count.index) 
  availability_zone       = element(local.availability_zones_names, count.index)
  
  map_public_ip_on_launch = false

  tags = {
    "Name" = "${var.env.prefix}-vpc-private-subnet-${count.index}"
  }
}

resource "aws_nat_gateway" "nat" {
  count  = (var.config.deployment_mode == "public" ? var.config.vpc_dcv_subnets_az_count : 0)

  allocation_id = element(aws_eip.nat_eip.*.id, count.index)
  subnet_id     = element(aws_subnet.subnet_public.*.id, count.index)
  connectivity_type  ="public"
  tags = {
    "Name" = "${var.env.prefix}-vpc-nat-${count.index}"
  }
}

resource "aws_route_table" "public" {
  count  = (var.config.deployment_mode == "public" ? var.config.vpc_dcv_subnets_az_count : 0)
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" : "${var.env.prefix}-vpc-rtb-public-${count.index}"
  }
}

resource "aws_route_table" "private" {
  count  = (var.config.deployment_mode == "public" ? var.config.vpc_dcv_subnets_az_count : 0)
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    "Name" : "${var.env.prefix}-vpc-rtb-private-${count.index}"
  }
}

resource "aws_route" "public" {
  count  = (var.config.deployment_mode == "public" ? var.config.vpc_dcv_subnets_az_count : 0)

  route_table_id         = element(aws_route_table.public.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
}

resource "aws_route" "private" {
  count  = (var.config.deployment_mode == "public" ? var.config.vpc_dcv_subnets_az_count : 0)

  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat.*.id, count.index)
}

resource "aws_route_table_association" "public" {
  count  = (var.config.deployment_mode == "public" ? var.config.vpc_dcv_subnets_az_count : 0)

  subnet_id      = element(aws_subnet.subnet_public.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count  = (var.config.deployment_mode == "public" ? var.config.vpc_dcv_subnets_az_count : 0)

  subnet_id      = element(aws_subnet.subnet_private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

######################################################################

# /* VPC Flow logs configuration */
# resource "aws_cloudwatch_log_group" "vpc_flow_log_group" {
#   name              = "/aws/vpc/flow-log/${var.env.prefix}/${formatdate("YYYYMMDD-hhmmss", timestamp())}"
#   kms_key_id        = "arn:aws:kms:${var.env.region}:${var.env.account_id}:key/${var.module_encryption.kms_key.id}"
#   retention_in_days = 30

#   lifecycle {
#     create_before_destroy = true
#   }  
# }

# resource "aws_iam_role" "vpc_flow_log_role" {
#   name = "${var.env.prefix}-vpc-flow-log"
#   assume_role_policy = jsonencode(
#     {
#       "Version": "2012-10-17",
#       "Statement": [
#         {
#           "Sid": "",
#           "Effect": "Allow",
#           "Principal": {
#             "Service": "vpc-flow-logs.amazonaws.com"
#           },
#           "Action": "sts:AssumeRole"
#         }
#       ]
#     }  
#   )
# }

# resource "aws_iam_role_policy" "vpc_flow_log_policy" {
#   name = "${var.env.prefix}-vpc-flow-log"
#   role = aws_iam_role.vpc_flow_log_role.id
#   policy = jsonencode(
#     {
#       "Version": "2012-10-17",
#       "Statement": [
#         {
#           "Action": [
#             "logs:CreateLogGroup",
#             "logs:CreateLogStream",
#             "logs:PutLogEvents",
#             "logs:DescribeLogGroups",
#             "logs:DescribeLogStreams"
#           ],
#           "Effect": "Allow",
#           "Resource": "*"
#         }
#       ]
#     }
#   )
# }

# resource "aws_flow_log" "vpc_flow_log" {
#   vpc_id = aws_vpc.vpc.id
  
#   iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
#   log_destination = aws_cloudwatch_log_group.vpc_flow_log_group.arn
#   traffic_type    = "ALL"

#   depends_on      = [
#     aws_iam_role.vpc_flow_log_role,
#     aws_cloudwatch_log_group.vpc_flow_log_group
#   ]
# }