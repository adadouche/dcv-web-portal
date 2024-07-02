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

variable "module_authentication" {
  description = "the authentication module"
}

variable "module_encryption" {
  description = "the encryption module"
}

variable "module_network" {
  description = "the network module"
}

#######################################################

variable "config" {
  description = "the module extra configuration"
  type = object({
    template_config_folder = string
    connection_gateway_config = optional(object({
      udp_port                 = number
      tcp_port                 = number
      health_check_port        = number       
    }))    
    dcv_server_config = optional(object({
      udp_port                 = number
      tcp_port                 = number
      health_check_port        = number       
    }))
  })
}

#######################################################
