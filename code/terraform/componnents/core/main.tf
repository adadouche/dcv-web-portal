# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

terraform {
  required_version = ">= 1.3.0, < 2.0.0"  
  # required_version = "~> 1.3.0"

  required_providers {
    aws = {
      # version = "~> 4.14"
      version = "~> 5.22.0"
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
  authentication_config = var.authentication_config
  dcv_config            = var.dcv_config

  deployment_mode = (var.network_config.deployment_mode == null ? "public" : var.network_config.deployment_mode)
  ip_allow_list_enabled = (var.network_config.ip_allow_list_enabled == null ? true: var.network_config.ip_allow_list_enabled)

  network_config = {
    deployment_mode   = local.deployment_mode

    ip_allow_list_enabled = local.ip_allow_list_enabled
    ip_allow_list         = var.network_config.ip_allow_list

  }

  network_config_create_new = merge (
    local.network_config,
    {
      dcv = {
        cidr_block        = var.network_config.vpc_dcv_cidr_block
        subnets_az_count  = var.network_config.vpc_dcv_subnets_az_count
        subnets_cidr_bits = var.network_config.vpc_dcv_subnets_cidr_bits
      }
      image_builder = {
        cidr_block         = var.network_config.vpc_image_builder_cidr_block
        subnets_cidr_bits  = var.network_config.vpc_image_builder_subnets_cidr_bits
      }
    }
  )

  network_config_reuse_existing = merge (
    local.network_config,
    {
      dcv = {
        vpc_id                  = var.network_config.vpc_dcv_existing_id
        public_subnet_ids       = var.network_config.vpc_dcv_existing_public_subnet_ids
        private_subnet_ids      = var.network_config.vpc_dcv_existing_private_subnet_ids
      }
      image_builder = {
        vpc_id                  = var.network_config.vpc_image_builder_existing_id
        public_subnet_id        = var.network_config.vpc_image_builder_existing_public_subnet_id
      }
    }
  )
}
