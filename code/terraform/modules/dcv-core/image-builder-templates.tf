# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  templates_extension = "json"
  templates_folder    = "templates"
  templates_name      = "connection-gateway"

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

    kms_key_id              = var.module_encryption.kms_key.id

    asg_load_balancer_arn   = aws_lb.load_balancer.arn
    asg_vpc_id              = var.module_network.vpc.id

    image_builder_instance_profile        = aws_iam_instance_profile.image_builder_instance_profile.name
    image_builder_pipeline_logs           = aws_s3_bucket.pipeline_logs.id

    vpc_subnet_id_image_builder           = var.module_network.vpc_image_builder_subnet.id
    vpc_subnet_ids_target                 = var.module_network.vpc_subnets_private.*.id

    vpc_security_group_ids_image_builder  = [local.vpc_security_groups["image-builder"].id]
    vpc_security_group_ids_target         = [local.vpc_security_groups["${local.templates_name}-instances"].id, local.vpc_security_groups["vpce"].id]

    dcv_lambda_update_tags_function_name  = local.lambdas["image-builder-update-tags"].lambda.function_name
    dcv_lambda_run_pipeline_function_name = local.lambdas["image-builder-run-pipeline"].lambda.function_name
  }
}
