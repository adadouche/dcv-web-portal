# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

output "config" {
  value = var.config
}

######################################################################

output "dcv_lambdas" {
  value = local.lambdas
}

######################################################################

output "load_balancer" {
  value = aws_lb.load_balancer
}

output "vpc_security_groups" {
  value = local.vpc_security_groups
}

output "vpc_subnets_private" {
  value = var.module_network.vpc_subnets_private
}

output "api_gateway_rest_api" {
  value = aws_api_gateway_rest_api.api_gateway_rest_api
}

output "image_builder_instance_profile" {
  value = aws_iam_instance_profile.image_builder_instance_profile
}

output "image_builder_pipeline_logs" {
  value = aws_s3_bucket.pipeline_logs
}

output "image_builder_bucket_download" {
  value = aws_s3_bucket.downloads
}

output "image_builder_bucket_pipeline" {
  value = aws_s3_bucket.pipeline_logs
}

######################################################################

output "region" {
  value = local.region
}

output "project" {
  value = local.project
}

output "application" {
  value = local.application
}

output "environment" {
  value = local.environment
}

output "account_id" {
  value = local.account_id
}

output "prefix" {
  value = local.prefix
}

output "deploymentMode" {
  value = local.deploymentMode
}

output "useCognitoProxy" {
  value = local.useCognitoProxy
}

output "userPoolId" {
  value = local.userPoolId
}

output "userPoolWebClientId" {
  value = local.userPoolWebClientId
}

output "userPoolEndpoint" {
  value = local.userPoolEndpoint
}

output "userPoolEndpointProxy" {
  value = local.userPoolEndpointProxy
}

output "identityPoolId" {
  value = local.identityPoolId
}

output "identityPoolEndpoint" {
  value = local.identityPoolEndpoint
}

output "identityPoolEndpointProxy" {
  value = local.identityPoolEndpointProxy
}

output "apiEndpoint" {
  value = local.apiEndpoint
}

output "apiEndpointId" {
  value = local.apiEndpointId
}

output "connectionGatewayLoadBalancerEndpoint" {
  value = local.connectionGatewayLoadBalancerEndpoint
}

output "connectionGatewayLoadBalancerPort" {
  value = local.connectionGatewayLoadBalancerPort
}

######################################################################