# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  interface_vpc_endpoint = (var.module_network.config.deployment_mode == "public" ? {} : {
      api-gateway  = "execute-api",
      sts          = "sts",
      ssm          = "ssm",
      ssmmessages  = "ssmmessages",
      ec2messages  = "ec2messages",
      logs         = "logs",
      lambda       = "lambda",
    }  
  )
  gateway_vpc_endpoint = (var.module_network.config.deployment_mode == "public" ? {} : {
      s3       = "s3"
    }  
  )
}

# Create a VPC Endpoint - Interface
resource "aws_vpc_endpoint" "interface_vpc_endpoint" {
  for_each            = { for resources_name, endpoint_name in local.interface_vpc_endpoint: resources_name => endpoint_name }
  vpc_id              = var.module_network.vpc.id
  service_name        = "com.amazonaws.${var.env.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.module_network.vpc_subnets_private.*.id
  security_group_ids  = [aws_security_group.vpce_sg.id]

  tags = {
    "Name" = "${var.env.prefix}-vpce-${each.key}"
  }
}

# Create a VPC Endpoint - Gateway
resource "aws_vpc_endpoint" "gateway_vpc_endpoint" {
  for_each            = { for resources_name, endpoint_name in local.gateway_vpc_endpoint: resources_name => endpoint_name }
  service_name        = "com.amazonaws.${var.env.region}.${each.value}"
  vpc_endpoint_type   = "Gateway"
  vpc_id              = var.module_network.vpc.id
  route_table_ids     = [ for route_table in var.module_network.vpc_route_table_private : route_table.id ]

  tags = {
    "Name" = "${var.env.prefix}-vpce-${each.key}"
  }
}

locals {
  vpc_endpoints = {
    "s3"           = (var.module_network.config.deployment_mode == "public" ? null : aws_vpc_endpoint.gateway_vpc_endpoint["s3"])
    "api-gateway"  = (var.module_network.config.deployment_mode == "public" ? null : aws_vpc_endpoint.interface_vpc_endpoint["api-gateway"])
    "logs"         = (var.module_network.config.deployment_mode == "public" ? null : aws_vpc_endpoint.interface_vpc_endpoint["logs"])
    "ssm"          = (var.module_network.config.deployment_mode == "public" ? null : aws_vpc_endpoint.interface_vpc_endpoint["ssm"])
    "ssmmessages"  = (var.module_network.config.deployment_mode == "public" ? null : aws_vpc_endpoint.interface_vpc_endpoint["ssmmessages"])
    "ec2messages"  = (var.module_network.config.deployment_mode == "public" ? null : aws_vpc_endpoint.interface_vpc_endpoint["ec2messages"])
    "lambda"       = (var.module_network.config.deployment_mode == "public" ? null : aws_vpc_endpoint.interface_vpc_endpoint["lambda"])
  }
}