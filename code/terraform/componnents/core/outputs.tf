# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

output "env" {
  value = local.env
}

#######################################################

output "authentication_config" {
  value = local.authentication_config
}

output "network_config" {
  value = local.network_config
}

output "dcv_config" {
  value = local.dcv_config
}

#######################################################

output "module_encryption" {
  value = module.encryption
}

output "module_authentication" {
  sensitive = true
  value = module.authentication
}

output "module_network" {
  value = module.network
}

#######################################################