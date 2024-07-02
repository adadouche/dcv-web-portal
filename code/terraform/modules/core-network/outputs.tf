# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

output "config" {
  value = var.config
}

######################################################################

output "vpc" {
  value = (local.use_existing_vpcs ? module.network_reuse[0].vpc : module.network_create[0].vpc)
}

output "vpc_subnets_private" {
  value = (local.use_existing_vpcs ? module.network_reuse[0].vpc_subnets_private : module.network_create[0].vpc_subnets_private)
}

output "vpc_subnets_public" {
  value = (local.use_existing_vpcs ? module.network_reuse[0].vpc_subnets_public : module.network_create[0].vpc_subnets_public)
}

output "vpc_route_table_private" {
  value = (local.use_existing_vpcs ? module.network_reuse[0].vpc_route_table_private : module.network_create[0].vpc_route_table_private)
}

######################################################################

output "vpc_image_builder" {
  value = (local.use_existing_vpcs ? module.network_reuse[0].vpc_image_builder : module.network_create[0].vpc_image_builder)
}

output "vpc_image_builder_subnet" {
  value = (local.use_existing_vpcs ? module.network_reuse[0].vpc_image_builder_subnet : module.network_create[0].vpc_image_builder_subnet)
}

######################################################################
