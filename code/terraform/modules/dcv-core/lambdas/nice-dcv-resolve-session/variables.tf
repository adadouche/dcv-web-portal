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

variable "config" {
  description = "the module extra configuration"
  type = object({
    dcv_server_udp_port = number
    dcv_server_tcp_port = number
  })
}

#######################################################

