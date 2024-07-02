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
    user_pool = any
  })
}
#######################################################