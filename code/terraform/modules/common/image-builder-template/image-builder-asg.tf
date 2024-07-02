# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  asg_config  = lookup(var.config.template_content, "autoscaling_group", null) 
  asg_enabled = local.asg_config != null ? true : false
}

module "asg" {
  count  = (local.asg_enabled ? 1 : 0)

  depends_on = [
    aws_launch_template.launch_template
  ]

  source = "../image-builder-template-asg"
  env    = var.env

  config = {
    template_path          = var.config.template_path
    template_name          = var.config.template_name
    template_extension     = var.config.template_extension
    template_config_folder = var.config.template_config_folder
    
    template_content       = var.config.template_content

    launch_template_id     = aws_launch_template.launch_template.id

    asg_load_balancer_arn  = var.config.asg_load_balancer_arn
    asg_vpc_id             = var.config.asg_vpc_id
    asg_vpc_subnet_ids     = var.config.vpc_subnet_ids_target
  }
}