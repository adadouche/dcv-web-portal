# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

terraform {
  required_version = ">= 1.3.0, < 2.0.0"  
  # required_version = "~> 1.3.0"

  required_providers {
    aws = {
      # version = "~> 4.14"
      # version = "~> 5.22.0"
      version = "~> 5.35.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
  default_tags {
    tags = local.tags
  }
}

# Helpers references
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  tags        = {
    "project"     = var.project
    "application" = var.application
    "environment" = var.environment
  }  
  env = {
    project         = var.project
    region          = var.region
    application     = var.application
    environment     = var.environment
    account_id      = ( var.account_id == null ? data.aws_caller_identity.current.account_id : var.account_id )
    prefix          = var.prefix
    tags            = local.tags
  }
}

###############################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

locals{
  az_names          = [for i in range(var.config.dcv.subnets_az_count): data.aws_availability_zones.available.names[i]]
  
  subnet_cidr_block_public        = [for i in range(var.config.dcv.subnets_az_count): cidrsubnet(var.config.dcv.cidr_block, var.config.dcv.subnets_cidr_bits, i)] 
  subnet_cidr_block_private       = [for i in range(var.config.dcv.subnets_az_count): cidrsubnet(var.config.dcv.cidr_block, var.config.dcv.subnets_cidr_bits, i+var.config.dcv.subnets_az_count)] 
  subnet_cidr_block_image_builder = cidrsubnet(var.config.image_builder.cidr_block, var.config.image_builder.subnets_cidr_bits, 1)
}

###############################################################################
