# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# # Prefix lists will let us reduce the amount of traffic we see
# resource "aws_ec2_managed_prefix_list" "allowed_ips" {
#   name           = "Allowed traffic via the network load balancer"
#   address_family = "IPv4"
#   max_entries    = 20

#   entry {
#     cidr        = "0.0.0.0/0"
#     description = "Everywhere"
#   }
# }

resource "aws_security_group" "elb_sg" {
  name        = "${var.env.prefix}-elb"
  description = "Security Group for Elastic Load Balancer"
  vpc_id      = var.module_network.vpc.id

  ingress {
    description = "Allow inbound from anywhere"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
    # can restrict with ip_allow_list if needed
  }

  egress {
    description = "Allow outbound to anywhere within the VPC"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = [var.module_network.vpc.cidr_block]
  }

  egress {
    description = "Allow outbound to anywhere"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  tags = {
    "Name" : "${var.env.prefix}-elb"
  }
}

# Define the security group applied to connection gateway instance
resource "aws_security_group" "gateway_instances_sg" {
  name        = "${var.env.prefix}-dcv-connection-gateway-instances"
  description = "NICE DCV connection gateway instances SG"
  vpc_id      = var.module_network.vpc.id

  # ingress {
  #   description = "Allow inbound from anywhere within the VPC"
  #   from_port   = "0"
  #   to_port     = "0"
  #   protocol    = "-1"
  #   cidr_blocks = [var.module_network.vpc.cidr_block]
  # }

  ingress {
    description = "Inbound TCP from NLB SG"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    security_groups = [aws_security_group.elb_sg.id]
  }

  egress {
    description = "Allow outbound to anywhere within the VPC"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = [var.module_network.vpc.cidr_block]
  }
  
  egress {
    description = "Allow outbound to anywhere"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    "Name" : "${var.env.prefix}-dcv-connection-gateway-instances"
  }
}

# Define the security group applied to EC2 builder instance
resource "aws_security_group" "image_builder_sg" {
  name        = "${var.env.prefix}-image-builder"
  description = "Security Group for EC2 image builder instances"
  vpc_id      = var.module_network.vpc_image_builder.id

  ingress {
    description = "Allow inbound from anywhere within the VPC"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = [var.module_network.vpc.cidr_block]
  }

  egress {
    description      = "Allow outbound to anywhere"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    "Name" : "${var.env.prefix}-image-builder"
  }
}

# Define the security group applied to running instance
resource "aws_security_group" "workstations_instances_sg" {
  name        = "${var.env.prefix}-dcv-worstations-instances"
  description = "Workstations instances SG"
  vpc_id      = var.module_network.vpc.id

  # ingress {
  #   description = "Allow inbound from anywhere within the VPC"
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = [var.module_network.vpc.cidr_block]
  # }

  ingress {
    description = "Inbound from Connection Gateway SG"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    security_groups = [aws_security_group.gateway_instances_sg.id]
  }

  egress {
    description = "Allow outbound to anywhere"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  tags = {
    "Name" : "${var.env.prefix}-dcv-worstations-instances"
  }
}

# Define the security group
resource "aws_security_group" "vpce_sg" {
  name   = "${var.env.prefix}-dcv-vpce"
  vpc_id = var.module_network.vpc.id

  ingress {
    description = "Allow inbound from anywhere within the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.module_network.vpc.cidr_block]
  }

  egress {
    description = "Allow outbound to anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "${var.env.prefix}-vpce"
  }
}

resource "aws_security_group" "proxy_instances_sg" {
  name        = "${var.env.prefix}-proxy-instances"  
  description = "Security Group for Proxy instances"

  vpc_id      = var.module_network.vpc.id

  ingress {
    description = "Allow inbound from anywhere within the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.module_network.vpc.cidr_block]
  }

  ingress {
    description = "Inbound HTTP from NLB SG"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    security_groups = [aws_security_group.elb_sg.id]
  }

  egress {
    description      = "Allow outbound to anywhere"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  tags = {
    "Name" : "${var.env.prefix}-proxy-instances"
  }
}

locals {
  vpc_security_groups = {
    "connection-gateway-instances" = aws_security_group.gateway_instances_sg
    "workstations-instances"       = aws_security_group.workstations_instances_sg
    "web-proxy-instances"          = aws_security_group.proxy_instances_sg
    "image-builder"                = aws_security_group.image_builder_sg
    "vpce"                         = aws_security_group.vpce_sg
    "elb"                          = aws_security_group.elb_sg
  }
}