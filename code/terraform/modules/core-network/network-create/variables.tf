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

    ip_allow_list_enabled = bool
    ip_allow_list         = list(string)
    
    vpc_dcv_cidr_block         = string
    vpc_dcv_subnets_az_count   = number
    vpc_dcv_subnets_cidr_bits  = number

    vpc_image_builder_cidr_block        = string
    vpc_image_builder_subnets_cidr_bits = number
  })
}

#######################################################
