# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

variable "prefix" {
  description = "Identifier prefix (max size: 12 characters)"
  type        = string
  # default     = "vdi"
  validation {
    condition = length(var.prefix) <= 15
    error_message = "Valid value is at most 12 characters."
  }
}

variable "project" {
  description = "Project identifier (max size: 12 characters)"
  type        = string
  # default     = "vdi"
  validation {
    condition = length(var.project) <= 12
    error_message = "Valid value is at most 12 characters."
  }
}

variable "application" {
  description = "application identifier"
  type        = string
  default     = "core"
}

variable "environment" {
  description = "Environment identifier (allowed: dev, prod)"
  type        = string
  validation {
    condition = contains(["dev", "prod"], var.environment)
    error_message = "Valid value is one of the following: dev, prod."
  }
}

variable "region" {
  description = "AWS deployment region (default: eu-west-1)"
  type        = string
  default     = "eu-west-1"
  validation {
    condition = contains(["af-south-1","ap-east-1","ap-northeast-1","ap-northeast-2","ap-northeast-3","ap-south-1","ap-south-2","ap-southeast-1","ap-southeast-2","ap-southeast-3","ap-southeast-4","ca-central-1","eu-central-1","eu-central-2","eu-north-1","eu-south-1","eu-south-2","eu-west-1","eu-west-2","eu-west-3","il-central-1","me-central-1","me-south-1","sa-east-1","us-east-1","us-east-2","us-gov-east-1","us-gov-west-1","us-west-1","us-west-2"], var.region)
    error_message = "Valid value is one of the following: af-south-1,  ap-east-1,  ap-northeast-1,  ap-northeast-2,  ap-northeast-3,  ap-south-1,  ap-south-2,  ap-southeast-1,  ap-southeast-2,  ap-southeast-3,  ap-southeast-4,  ca-central-1,  eu-central-1,  eu-central-2,  eu-north-1,  eu-south-1,  eu-south-2,  eu-west-1,  eu-west-2,  eu-west-3,  il-central-1,  me-central-1,  me-south-1,  sa-east-1,  us-east-1,  us-east-2,  us-gov-east-1,  us-gov-west-1,  us-west-1,  us-west-2 ."
  }
}

variable "account_id" {
  description = "AWS deployment account id (default : profile account id)"
  type        = string
  default     = null
  validation {
    condition = var.account_id == null || length(( var.account_id == null ? "" : var.account_id)) == 12
    error_message = "Provide a valid AWS Account id."
  }
}

######################################################################

variable "config" {
  type        = object({
    deployment_mode   = string
    dcv = object({
      cidr_block         = string
      subnets_az_count   = number
      subnets_cidr_bits  = number
    })
    image_builder = object({
      cidr_block        = string
      subnets_cidr_bits = number
    })
  })
  default = {
    deployment_mode = "public"
    dcv = {
      cidr_block        = "172.31.0.0/16"
      subnets_az_count  = 2 
      subnets_cidr_bits = 4
    }
    image_builder = {
      cidr_block        = "172.31.1.0/24"
      subnets_cidr_bits = 4
    }
  }
  description = "The networking config"
  validation {
    condition = ( 
      contains(["public", "private"], var.config.deployment_mode)
    )
    error_message = "Valid values for config.deployment_mode are : public & private. Default is public"
  }
}

######################################################################
