# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

variable "prefix" {
  description = "Identifier prefix (max size: 12 characters)"
  type        = string
  # default     = "vdi"
  validation {
    condition = length(var.prefix) <= 12
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

variable "authentication_config" {
  type        = object({
    admin_group_name  = optional(string)
    admin_user = optional(object({      
      admin_login              = string
      admin_full_name          = string
      admin_email              = string
      admin_temporary_password = string
    }))
  })
  default     = {
    admin_group_name  = "admin"
    admin_user        = null
  }
  description = "The cognito config"
}

######################################################################

variable "network_config" {
  type        = object({
    deployment_mode   = string

    ip_allow_list_enabled = optional(bool)
    ip_allow_list         = optional(list(string))

    use_existing_vpcs = optional(bool)

    vpc_dcv_cidr_block         = optional(string)
    vpc_dcv_subnets_az_count   = optional(number)
    vpc_dcv_subnets_cidr_bits  = optional(number)  

    vpc_image_builder_cidr_block        = optional(string)
    vpc_image_builder_subnets_cidr_bits = optional(number)

    vpc_dcv_existing_id                 = optional(string)
    vpc_dcv_existing_public_subnet_ids  = optional(list(string))
    vpc_dcv_existing_private_subnet_ids = optional(list(string))

    vpc_image_builder_existing_id                = optional(string)
    vpc_image_builder_existing_public_subnet_id  = optional(string)
  })
  default = {
    deployment_mode = "public"

    ip_allow_list_enabled = true
    ip_allow_list         = []
    
    use_existing_vpcs  = false

    vpc_dcv_cidr_block        = "192.168.0.0/16"
    vpc_dcv_subnets_az_count  = 2 
    vpc_dcv_subnets_cidr_bits = 4

    vpc_image_builder_cidr_block        = "192.168.1.0/24"
    vpc_image_builder_subnets_cidr_bits = 2

  }
  description = "The networking config"
  validation {
    condition = ( 
      contains(["public", "private"], var.network_config.deployment_mode)
    )
    error_message = "Valid values for network_config.deployment_mode are : public & private. Default is public"
  }
  validation {
    condition = (
      ( var.network_config.ip_allow_list_enabled == null || var.network_config.use_existing_vpcs == false )
      ||
      (    var.network_config.ip_allow_list_enabled == true 
        && var.network_config.ip_allow_list != null 
        && length(( var.network_config.ip_allow_list != null ? var.network_config.ip_allow_list : [] )) > 0
      )
    )
    error_message = "You have enabled the ip_allow_list_enabled flag but ip_allow_list is null or empty"
  }
  validation {
    condition = (
      ( var.network_config.ip_allow_list_enabled == null || var.network_config.use_existing_vpcs == false )
      ||
      (    var.network_config.ip_allow_list_enabled == true 
        && var.network_config.ip_allow_list != null 
        &&  alltrue(
          [for cidr in ( var.network_config.ip_allow_list != null ? var.network_config.ip_allow_list : [] ) : split("/", cidr)[1] >= 16 && split("/", cidr)[1] <= 32]
        )
      )
    )
    error_message = "You have enabled the ip_allow_list_enabled flag but but provided an invalid CIRD range list (CIDR range must be between /16 and /32)."
  }
  validation {
    condition = (
      ( var.network_config.ip_allow_list_enabled == null || var.network_config.use_existing_vpcs == false )
      ||
      (    var.network_config.ip_allow_list_enabled == true 
        && var.network_config.ip_allow_list != null 
        &&  alltrue(
          [for cidr in ( var.network_config.ip_allow_list != null ? var.network_config.ip_allow_list : [] ) : cidrhost(cidr, 0) == split("/", cidr)[0]]
        )
      )
    )
    error_message = "You have enabled the ip_allow_list_enabled flag but provided an invalid CIRD range list (invalid CIDR range)."
  }
  validation {
    condition = (
      ( var.network_config.use_existing_vpcs != null && var.network_config.use_existing_vpcs == true )
      ||
      ( var.network_config.vpc_dcv_cidr_block == null || var.network_config.vpc_dcv_subnets_cidr_bits == null ? false : cidrhost(var.network_config.vpc_dcv_cidr_block, 0) == split("/", var.network_config.vpc_dcv_cidr_block)[0])
    )
    error_message = "The DCV VPC CIDR range to be created is invalid."
  }
  validation {
    condition = (
      ( var.network_config.use_existing_vpcs != null && var.network_config.use_existing_vpcs == true )
      ||
        ( var.network_config.vpc_dcv_cidr_block == null || var.network_config.vpc_dcv_subnets_cidr_bits == null ? false : split("/", var.network_config.vpc_dcv_cidr_block)[1] + var.network_config.vpc_dcv_subnets_cidr_bits <=28)
    )
    error_message = "The DCV Subnet CIDR bit value to be created is invalid."
  }
  validation {
    condition = (
      ( var.network_config.use_existing_vpcs != null && var.network_config.use_existing_vpcs == true )
      ||
      ( var.network_config.vpc_image_builder_cidr_block == null || var.network_config.vpc_image_builder_subnets_cidr_bits == null ? false : split("/", var.network_config.vpc_image_builder_cidr_block)[0] == cidrhost(var.network_config.vpc_image_builder_cidr_block, 0))
    )
    error_message = "The Image Builder VPC CIDR range to be created is invalid."
  }
  validation {
    condition = (
      ( var.network_config.use_existing_vpcs != null && var.network_config.use_existing_vpcs == true )
      ||
      ( var.network_config.vpc_image_builder_cidr_block == null || var.network_config.vpc_image_builder_subnets_cidr_bits == null ? false : split("/", var.network_config.vpc_image_builder_cidr_block)[1] + var.network_config.vpc_image_builder_subnets_cidr_bits <=28)
    )
    error_message = "The Image Builder Subnet CIDR bit value to be created is invalid."
  }
  validation {
    condition = (
      ! ( var.network_config.use_existing_vpcs != null && var.network_config.use_existing_vpcs == true )
      || 
      ( var.network_config.vpc_dcv_existing_id == null ? false : startswith(var.network_config.vpc_dcv_existing_id, "vpc-") && length(var.network_config.vpc_dcv_existing_id) == 21 )
    )
    error_message = "The DCV VPC Id to be reused is invalid (should start with 'vpc-' and have a length of 21 characters)."
  }
  validation {
    condition = (
      ! ( var.network_config.use_existing_vpcs != null && var.network_config.use_existing_vpcs == true )
      || 
      ( var.network_config.vpc_image_builder_existing_id == null ? false : startswith(var.network_config.vpc_image_builder_existing_id, "vpc-") && length(var.network_config.vpc_image_builder_existing_id) == 21 )
    )
    error_message = "The Image Builder VPC Id to be reused is invalid (should start with 'vpc-' and have a length of 21 characters)."
  }
  validation {
    condition = (
      ! ( var.network_config.use_existing_vpcs != null && var.network_config.use_existing_vpcs == true )
      ||( var.network_config.deployment_mode == "private" ) # no need of public subnet of deployment mode is private
      || 
      ( var.network_config.vpc_dcv_existing_private_subnet_ids == null || length((var.network_config.vpc_dcv_existing_private_subnet_ids == null ? [] : var.network_config.vpc_dcv_existing_private_subnet_ids)) == 0 ? false : alltrue([
          for subnet_id in var.network_config.vpc_dcv_existing_private_subnet_ids : startswith(subnet_id, "subnet-") && length(subnet_id) == 24 
        ])
      )
    )
    error_message = "The DCV Public Subnet Id list to be reused is invalid (should start with 'subnet-' and have a length of 24 characters)."
  }
  validation {
    condition = (
      ! ( var.network_config.use_existing_vpcs != null && var.network_config.use_existing_vpcs == true )
      || 
      ( var.network_config.vpc_dcv_existing_private_subnet_ids == null || length((var.network_config.vpc_dcv_existing_private_subnet_ids == null ? [] : var.network_config.vpc_dcv_existing_private_subnet_ids)) == 0 ? false : alltrue([
          for subnet_id in var.network_config.vpc_dcv_existing_private_subnet_ids : startswith(subnet_id, "subnet-") && length(subnet_id) == 24 
        ])
      )
    )
    error_message = "The DCV Private Subnet Id list to be reused is invalid (should start with 'subnet-' and have a length of 24 characters)."
  }
  validation {
    condition = (
      ! ( var.network_config.use_existing_vpcs != null && var.network_config.use_existing_vpcs == true )
      || 
      ( var.network_config.vpc_image_builder_existing_public_subnet_id == null || length((var.network_config.vpc_image_builder_existing_public_subnet_id == null ? "" : var.network_config.vpc_image_builder_existing_public_subnet_id)) == 0 ? false : alltrue([
          startswith(var.network_config.vpc_image_builder_existing_public_subnet_id, "subnet-") && length(var.network_config.vpc_image_builder_existing_public_subnet_id) == 24 
        ])
      )
    )
    error_message = "The Image Builder Public Subnet Id to be reused is invalid (should start with 'subnet-' and have a length of 24 characters)."
  }

}

######################################################################

variable "dcv_config" {
  type        = object({
    connection_gateway_config = object({
      udp_port                 = number
      tcp_port                 = number
      health_check_port        = number       
    })
    dcv_server_config = object({
      udp_port                 = number
      tcp_port                 = number
      health_check_port        = number       
    })
  })
  default = {
    connection_gateway_config = {
      udp_port                = 8443
      tcp_port                = 8443
      health_check_port       = 8989
    }
    dcv_server_config = {
      udp_port                = 8443
      tcp_port                = 8443
      health_check_port       = 8989   
    }
  }
  description = "The NICE DCV config"
}
######################################################################
