# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  lambda_modules = {

    # "cognito-proxy-idp"         = module.lambda_cognito_proxy_idp
    # "cognito-proxy-identity"    = module.lambda_cognito_proxy_identity

    "nice-dcv-auth"             = module.lambda_dcv_auth
    "nice-dcv-resolve-session"  = module.lambda_dcv_resolve_session    
    "nice-dcv-server-configure" = module.lambda_dcv_server_configure

    "image-builder-run-pipeline" = module.lambda_image_builder_run_pipeline
    "image-builder-update-tags"  = module.lambda_image_builder_update_tags
    
    "asg-instance-refresh" = module.lambda_asg_instance_refresh
  
    "secret-get"          = module.lambda_secret_get

    "templates-list"      = module.lambda_templates_list
    "templates-launch"    = module.lambda_templates_launch
    
    "instances-hibernate" = module.lambda_instances_hibernate
    "instances-list"      = module.lambda_instances_list
    "instances-reboot"    = module.lambda_instances_reboot
    "instances-start"     = module.lambda_instances_start
    "instances-stop"      = module.lambda_instances_stop
    "instances-terminate" = module.lambda_instances_terminate
  }
  
  lambdas = {
    for key, value in local.lambda_modules : 
      value.lambda_key => {
        "lambda"             = value.lambda
        "lambda_key"         = value.lambda_key
        "lambda_role"        = value.lambda_role
        "lambda_invoke_role" = value.lambda_invoke_role
      }
  }
}

