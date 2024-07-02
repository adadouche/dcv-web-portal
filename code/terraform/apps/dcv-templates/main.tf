# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

terraform {
  required_version = ">= 1.3.0, < 2.0.0"  

  required_providers {
    aws = {
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

module "dcv_template_builder" {
  source     = "../../modules/dcv-templates"
  env        = local.env
  
  config = {
    template_config_folder = "${abspath(path.module)}/config"

    kms_key_id = var.config.kms_key_id
    
    vpc_subnet_id_image_builder           = var.config.vpc_subnet_id_image_builder
    vpc_subnet_ids_workstation            = var.config.vpc_subnet_ids_workstation
    vpc_security_group_ids_image_builder  = var.config.vpc_security_group_ids_image_builder
    vpc_security_group_ids_workstation    = var.config.vpc_security_group_ids_workstation

    dcv_lambda_update_tags_function_name  = var.config.dcv_lambda_update_tags_function_name
    dcv_lambda_run_pipeline_function_name = var.config.dcv_lambda_run_pipeline_function_name

    image_builder_bucket_download  = var.config.image_builder_bucket_download
    image_builder_bucket_pipeline  = var.config.image_builder_bucket_pipeline
    image_builder_instance_profile = var.config.image_builder_instance_profile
  }
}