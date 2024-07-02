# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

output "env_region" {
  value = local.env.region
}

######################################################################

output "env_project" {
  value = local.env.project
}

output "env_application" {
  value = local.env.application
}

output "env_environment" {
  value = local.env.environment
}

output "env_account_id" {
  value = local.env.account_id
}

output "env_prefix" {
  value = local.env.prefix
}

######################################################################

output "config_deploymentMode" {
  value = local.network_config.deployment_mode
}

output "config_use_existing_vpcs" {
  value = local.network_config.use_existing_vpcs
}

output "config_ip_allow_list_enabled" {
  value = local.network_config.ip_allow_list_enabled
}

output "config_ip_allow_list" {
  value = local.network_config.ip_allow_list
}

######################################################################

output "portal_userPoolId" {
  value = module.dcv.userPoolId
}

output "portal_userPoolWebClientId" {
  value = module.dcv.userPoolWebClientId
}

output "portal_userPoolEndpoint" {
  value = module.dcv.userPoolEndpoint
}

output "portal_identityPoolId" {
  value = module.dcv.identityPoolId
}

output "portal_apiEndpoint" {
  value = module.dcv.apiEndpoint
}

output "portal_connectionGatewayLoadBalancerEndpoint" {
  value = module.dcv.connectionGatewayLoadBalancerEndpoint
}

output "portal_connectionGatewayLoadBalancerPort" {
  value = module.dcv.connectionGatewayLoadBalancerPort
}

######################################################################

output "frontend_url" {
  value = module.dcv_portal.url
}

output "frontend_admin_login" {
  value = local.authentication_config.admin_user.admin_login
}

output "frontend_admin_email" {
  value = local.authentication_config.admin_user.admin_email
}

######################################################################
