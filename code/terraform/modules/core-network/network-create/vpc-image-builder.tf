# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_vpc" "ib_vpc" {
  cidr_block           = var.config.vpc_image_builder_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name" = "${var.env.prefix}-image-builder"
  }
}

/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "ib_igw" {
  vpc_id = aws_vpc.ib_vpc.id

  tags = {
    "Name" = "${var.env.prefix}-ib-igw"
  }  
}

resource "aws_route_table" "ib_public" {
  vpc_id = aws_vpc.ib_vpc.id

  tags = {
    "Name" : "${var.env.prefix}-ib-rtb-public"
  }
}

resource "aws_route" "ib_public" {
  route_table_id         = aws_route_table.ib_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ib_igw.id
}

resource "aws_subnet" "ib_subnet_public" {
  vpc_id = aws_vpc.ib_vpc.id

  cidr_block              = local.subnet_cidr_block_image_builder
  availability_zone       = element(local.availability_zones_names, 1)
  
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.env.prefix}-ib-public-subnet"
  }
}

resource "aws_route_table_association" "ib_public" {
  subnet_id      = aws_subnet.ib_subnet_public.id
  route_table_id = aws_route_table.ib_public.id
}

######################################################################

# /* VPC Flow logs configuration */
# resource "aws_cloudwatch_log_group" "ib_vpc_flow_log_group" {
#   name              = "/aws/vpc-image-builder/flow-log/${var.env.prefix}/${formatdate("YYYYMMDD-hhmmss", timestamp())}"
#   kms_key_id        = "arn:aws:kms:${var.env.region}:${var.env.account_id}:key/${var.module_encryption.kms_key.id}"
#   retention_in_days = 30

#   lifecycle {
#     create_before_destroy = true
#   }  
# }

# resource "aws_iam_role" "ib_vpc_flow_log_role" {
#   name = "${var.env.prefix}-vpc-image-builder-flow-log"
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

# resource "aws_iam_role_policy" "ib_vpc_flow_log_policy" {
#   name = "${var.env.prefix}-vpc-flow-log"
#   role = aws_iam_role.ib_vpc_flow_log_role.id
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

# resource "aws_flow_log" "ib_vpc_flow_log" {
#   vpc_id = aws_vpc.ib_vpc.id

#   iam_role_arn    = aws_iam_role.ib_vpc_flow_log_role.arn
#   log_destination = aws_cloudwatch_log_group.ib_vpc_flow_log_group.arn
#   traffic_type    = "ALL"

#   depends_on      = [
#     aws_iam_role.ib_vpc_flow_log_role,
#     aws_cloudwatch_log_group.ib_vpc_flow_log_group
#   ]
# }
