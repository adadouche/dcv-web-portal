# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  templates_extension = "json"
  templates_folder    = "templates"
  templates_name      = "*" 
    
  templates_vars = merge(
    {
      project     = var.env.project
      application = var.env.application
      environment = var.env.environment
      prefix      = var.env.prefix
      account_id  = var.env.account_id
      region      = var.env.region
      SourceInstanceARN = "$${ec2:SourceInstanceARN}"
    }
  )     

  templates_list = {
    for file_name in fileset("${var.config.template_config_folder}/${local.templates_folder}", "${local.templates_name}.${local.templates_extension}"): 
        lower(replace(file_name, ".${local.templates_extension}", "")) => {
          path    : "${var.config.template_config_folder}/${local.templates_folder}/${file_name}",
          content :  (
            local.templates_extension == "json" 
            ?
            jsondecode( templatefile("${var.config.template_config_folder}/${local.templates_folder}/${file_name}", local.templates_vars ) )
            :
            yamldecode( templatefile("${var.config.template_config_folder}/${local.templates_folder}/${file_name}", local.templates_vars ) )
          )
        }
  }

  template_default_os_config = jsondecode( file("${var.config.template_config_folder}/os_config.json") )
  template_default_config    = jsondecode( templatefile( "${var.config.template_config_folder}/default-template-config.json", local.templates_vars ) )  

  tags_instance = {
    for key, value in local.templates_list: 
      key => {
      }
  }

  tags_template = {
    for key, value in local.templates_list: 
      key => {
        "cognito_groups"     : join(",", value.content.cognito_groups),
        "description"        : value.content.description,
        "instance_families"  : substr( join(",", value.content.instance_families),  0, 254),
        "instance_sizes"     : substr( join(",", value.content.instance_sizes),    0, 254),
        "volume"             : jsonencode({
            "type" : value.content.volume_type
            "size" : {
              "min": lookup(value.content, "volume_size_min", value.content.volume_size), 
              "max": lookup(value.content, "volume_size_max", value.content.volume_size), 
              "default": value.content.volume_size
            },
            "iops" : {
              "min": lookup(value.content, "volume_iops_min", value.content.volume_iops), 
              "max": lookup(value.content, "volume_iops_max", value.content.volume_iops),  
              "default": value.content.volume_iops
            },
            "throughput" : {
              "min": lookup(value.content, "volume_throughput_min", value.content.volume_throughput), 
              "max": lookup(value.content, "volume_throughput_max", value.content.volume_throughput), 
              "default": value.content.volume_throughput
            }
          }
        ),        
        "subnets" :  join(",", var.config.vpc_subnet_ids_workstation),
      }
    }
}

module "image_builder_templates" {
  depends_on = [ 
    module.image_builder_components
  ]

  for_each   = local.templates_list
  source     = "../common/image-builder-template"
  env        = var.env
  
  config = {
    template_path           = each.value.path
    template_name           = each.key
    template_extension      = local.templates_extension
    template_config_folder  = var.config.template_config_folder

    template_default_os_config = local.template_default_os_config
    template_default_config    = local.template_default_config
    template_content           = each.value.content

    tags_instance = local.tags_instance[each.key]
    tags_template = local.tags_template[each.key]

    kms_key_id                 = var.config.kms_key_id

    image_builder_instance_profile        = var.config.image_builder_instance_profile
    image_builder_pipeline_logs           = var.config.image_builder_bucket_pipeline

    vpc_subnet_id_image_builder           = var.config.vpc_subnet_id_image_builder
    vpc_subnet_ids_target                 = var.config.vpc_subnet_ids_workstation

    vpc_security_group_ids_image_builder  = var.config.vpc_security_group_ids_image_builder
    vpc_security_group_ids_target         = var.config.vpc_security_group_ids_workstation

    dcv_lambda_update_tags_function_name  = var.config.dcv_lambda_update_tags_function_name
    dcv_lambda_run_pipeline_function_name = var.config.dcv_lambda_run_pipeline_function_name
  }
}

