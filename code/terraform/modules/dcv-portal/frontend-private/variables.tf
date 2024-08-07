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

variable "module_network" {
  description = "the network module"
}

variable "module_encryption" {
  description = "the encrytion module"
}

variable "module_dcv" {
  description = "the dcv module"
}

#######################################################

variable "config" {
  description = "the module extra configuration"
  type = object({
    template_config_folder = string
    web_content_bucket_id          = string
    web_content_bucket_domain_name = string
    api_endpoint                   = string
  })
}
