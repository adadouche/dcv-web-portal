# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0


locals {
  components_extension = "yml"
  components_folder    = "components"
  components_name      = "*"
  
  imagebuilder_components_list = {
    for file_name in fileset("${var.config.template_config_folder}/${local.components_folder}", "${local.components_name}.${local.components_extension}"): 
        lower(replace(file_name, ".${local.components_extension}", "")) => "${var.config.template_config_folder}/${local.components_folder}/${file_name}"
  }
}

module "image_builder_components" {
  for_each   = local.imagebuilder_components_list
  source     = "../common/image-builder-component"
  env        = var.env
  
  config = {
    component_path      = each.value
    component_name      = each.key
    component_extension = local.components_extension

    download_folder  = "${abspath(path.module)}/dist"
    download_bucket  = "${var.config.image_builder_bucket_download}"
  }

  kms_key_id        = var.config.kms_key_id  
}