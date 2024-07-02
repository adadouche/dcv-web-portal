# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  region          = var.env.region
  project         = var.env.project
  application     = var.env.application
  environment     = var.env.environment
  account_id      = var.env.account_id
  prefix          = var.env.prefix

  deploymentMode      = var.module_network.config.deployment_mode
  useCognitoProxy     = var.module_authentication.config.use_cognito_proxy
  
  apiEndpoint         = aws_api_gateway_stage.api_gateway_stage.invoke_url
  apiEndpointId       = aws_api_gateway_rest_api.api_gateway_rest_api.id

  identityPoolId      = var.module_authentication.identity_pool.id
  userPoolId          = var.module_authentication.user_pool.id
  userPoolWebClientId = var.module_authentication.user_pool_client.id
  
  identityPoolEndpoint = local.cognito_resources_names["identity"]
  userPoolEndpoint     = local.cognito_resources_names["idp"] 
  
  identityPoolEndpointProxy = "/${aws_api_gateway_stage.api_gateway_stage.stage_name}${module.cognito_resources["identity"].api_gateway_resource.path}" 
  userPoolEndpointProxy     = "/${aws_api_gateway_stage.api_gateway_stage.stage_name}${module.cognito_resources["idp"].api_gateway_resource.path}"

  connectionGatewayLoadBalancerEndpoint = aws_lb.load_balancer.dns_name
  connectionGatewayLoadBalancerPort     = var.config.connection_gateway_config.tcp_port
}
