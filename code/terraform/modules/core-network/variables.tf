# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

variable "env" {
  type = object({
    region          = string
    project         = string
    application     = string
    environment     = string
    account_id      = string
    prefix          = string
    tags            = map(string)
  })
  description = "the environment config"
}

#######################################################

variable "module_encryption" {
  description = "the encryption module"
}

#######################################################

variable "config" {
  description = "the module extra configuration"
  type = object({
    deployment_mode   = string
    use_existing_vpcs = bool

    ip_allow_list_enabled = optional(bool)
    ip_allow_list         = optional(list(string))
    
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
}

#######################################################
