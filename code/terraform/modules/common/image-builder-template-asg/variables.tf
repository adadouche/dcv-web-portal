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
    
    template_content       = any

    launch_template_id     = string

    asg_load_balancer_arn  = string
    asg_vpc_id             = string
    asg_vpc_subnet_ids     = list(string)
  })
}

#######################################################
