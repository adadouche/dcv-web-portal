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
    kms_key_id = string
    template_config_folder = string

    vpc_subnet_id_image_builder = string
    vpc_subnet_ids_workstation  = list(string)
    vpc_security_group_ids_image_builder  = list(string)
    vpc_security_group_ids_workstation    = list(string)

    dcv_lambda_update_tags_function_name  = string
    dcv_lambda_run_pipeline_function_name = string

    image_builder_bucket_download   = string
    image_builder_bucket_pipeline   = string
    image_builder_instance_profile  = string

  })
}

#######################################################
