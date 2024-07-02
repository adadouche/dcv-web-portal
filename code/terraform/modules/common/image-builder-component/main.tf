# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  download_path    =      "${var.config.download_folder}/${var.env.prefix}/${var.config.component_name}"
  download_path_s3 = "s3://${var.config.download_bucket}/${var.config.component_name}"

  components_vars = merge(
    {
      s3-bucket-uri = local.download_path_s3

      project       = var.env.project
      application   = var.env.application
      environment   = var.env.environment
      prefix        = var.env.prefix
      region        = var.env.region
      account_id    = var.env.account_id
    }
  )

  # the raw version is required else the resource attributes that cannot be determined until apply
  component_content       = ( var.config.component_extension == "json" ? jsondecode( templatefile(var.config.component_path, local.components_vars ) ) : yamldecode( templatefile(var.config.component_path, local.components_vars ) ) )
  component_content_raw   = ( var.config.component_extension == "json" ? jsondecode(         file(var.config.component_path) )                         : yamldecode(         file(var.config.component_path) ) )

  component_downloads_list = {
    for item in ( try(local.component_content_raw.downloads, {}) ) : 
      item.name => { 
        "name"     : item.name,
        "url"      : item.url,
        "filename" : item.filename
      }
  }
}
data "external" "get_next_versions" {
  program = ["sh", "${path.module}/scripts/get-next-versions.sh"]

  query = {
    region     = "${var.env.region}"
    account_id = "${var.env.account_id}"
    name       = "${var.env.prefix}-${var.config.component_name}"
  }
}

resource "null_resource" "component_downloads" {
  for_each = { for key, value in local.component_downloads_list: key => value }
  
  # lifecycle {
  #   create_before_destroy = true
  # }

  triggers = {
    download_path_s3     = local.download_path_s3
    download_path        = local.download_path
    download_url         = each.value.url
    download_filename    = each.value.filename
    # tsp                  = timestamp()
  }

  provisioner "local-exec" {
    when = create
    on_failure = continue
    command = <<-EOT
      echo "create"
  
      mkdir  -p       "${self.triggers.download_path}"
      wget  -nc -q -O "${self.triggers.download_path}/${self.triggers.download_filename}" "${self.triggers.download_url}" 
      aws   s3 cp     "${self.triggers.download_path}/${self.triggers.download_filename}"  ${self.triggers.download_path_s3}/${self.triggers.download_filename}
    EOT
  }
  
  provisioner "local-exec" {
    when = destroy
    on_failure = continue
    command = <<-EOT
      echo "destroy"
      aws s3 rm s3://${self.triggers.download_path_s3}/${self.triggers.download_filename} || echo "rm failed s3"
      rm -rf        "${self.triggers.download_path}/${self.triggers.download_filename}"   || echo "rm failed" 

      # if the folder is empty then delete the root folder too
      [ "$(ls -A "${self.triggers.download_path}")" ] || rm -rf "${self.triggers.download_path}" || echo "rm failed"
    EOT
  }
}

resource "aws_imagebuilder_component" "imagebuilder_components" {
  depends_on = [ 
    null_resource.component_downloads 
  ]
  lifecycle {
    create_before_destroy = true
  }

  name        = "${var.env.prefix}-${var.config.component_name}"
  platform    = "${local.component_content.os_platform}"
  version     = data.external.get_next_versions.result.next_component
  # version     = "1.0.0"
  description = "[${local.component_content.os_platform}][${var.config.component_name}]"
  kms_key_id  = "arn:aws:kms:${var.env.region}:${var.env.account_id}:key/${var.kms_key_id}"

  data = yamlencode({
    "schemaVersion" : local.component_content.schemaVersion,
    "parameters"    : local.component_content.parameters,
    "phases"        : local.component_content.phases
  })
}