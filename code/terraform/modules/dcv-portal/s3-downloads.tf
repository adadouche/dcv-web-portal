# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  dcv_client_downloads_path    = "${var.config.config_folder}/dcv_client_downloads.json"
  dcv_client_downloads_content = jsondecode( file(local.dcv_client_downloads_path) )

  dcv_client_downloads_list = {
    for key, url in ( try(local.dcv_client_downloads_content, {}) ) : 
      key => { 
        "name"     : key,
        "url"      : url,
        "filename" : basename(url)
      }
  }
}

resource "null_resource" "dcv_client_downloads" {
  for_each = { for key, value in local.dcv_client_downloads_list: key => value }

  triggers = {
    download_path = "${local.frontend_src}/public/downloads/${each.key}"
    download_url  = each.value.url
    tsp           = timestamp()
  }

  provisioner "local-exec" {
    when = create
    on_failure = continue
    command = <<-EOT
      echo "create"
      mkdir  -p       "${self.triggers.download_path}"
      wget  -nc -q -P "${self.triggers.download_path}" "${self.triggers.download_url}" 
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      rm -rf "${self.triggers.download_path}" || echo "rm failed"
    EOT
  }
}
