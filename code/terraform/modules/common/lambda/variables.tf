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
variable "function_name" {
  description = "the lambda function name"
}

variable "function_path" {
  description = "the lambda function path"
}

variable "function_role" {
  description = "the lambda function IAM role"
}

variable "function_config" {
  description = "the lambda function config"
}

