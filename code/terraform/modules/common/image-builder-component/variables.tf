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

variable "kms_key_id" {
  description = "the encryption key id"
  type        = string
}

#######################################################

variable "config" {
  description = "the module extra configuration"
  type = object({    
    component_path      = string
    component_name      = string
    component_extension = string
    
    download_folder  = string  
    download_bucket  = string  
  })
}

#######################################################
