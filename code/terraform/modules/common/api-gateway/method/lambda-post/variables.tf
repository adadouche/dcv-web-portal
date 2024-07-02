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
variable "method_rest_api" {
  description = "the resource rest api object"
}

variable "method_resource" {
  description = "the resource parent"
}

variable "method_authorization" {
  description = "the resource parent"
}

variable "method_authorizer" {
  description = "the resource parent"
}

#######################################################

variable "lambda_module" {
  description = "the lambda module"
}

#######################################################
