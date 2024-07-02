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
    admin_group_name  = string
    admin_user = optional(object({      
      admin_login              = string
      admin_full_name          = string
      admin_email              = string
      admin_temporary_password = string
    }))
    use_cognito_proxy = bool
  })
}


