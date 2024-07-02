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

variable "config" {
  description = "the module extra configuration"
  type = object({    
    template_path          = string
    template_name          = string
    template_extension     = string  
    template_config_folder = string 
    
    template_default_os_config = any
    template_default_config    = any
    template_content           = any

    kms_key_id    = string

    asg_load_balancer_arn                 = optional(string)
    asg_vpc_id                            = optional(string)

    image_builder_instance_profile        = string
    image_builder_pipeline_logs           = string

    vpc_subnet_id_image_builder           = string
    vpc_subnet_ids_target                 = list(string)

    vpc_security_group_ids_image_builder  = list(string)
    vpc_security_group_ids_target         = list(string)

    dcv_lambda_update_tags_function_name  = string    
    dcv_lambda_run_pipeline_function_name = string

    tags_instance = optional(any)
    tags_template = optional(any)

  })
}

#######################################################
