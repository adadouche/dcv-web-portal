# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "null_resource" "copy_source" {
  provisioner "local-exec" {
    when = create
    command = <<-EOT
      mkdir  -p "${var.function_path}/build/"
      mkdir  -p "${var.function_path}/output/"
      cp -r      ${var.function_path}/src/* ${var.function_path}/build/
      if [ -f "${var.function_path}/build/requirements.txt" ]
      then
          pip3 install -r ${var.function_path}/build/requirements.txt -t ${var.function_path}/build
      fi
            
    EOT    
  }
  
  provisioner "local-exec" {
    when = destroy
    on_failure = continue
    command = <<-EOT
      rm -rf ${self.triggers.function_path}/build  || echo "rm failed"
      rm -rf ${self.triggers.function_path}/output || echo "rm failed"
    EOT
  }

  triggers = {
    function_path = var.function_path
    
    changes_src = md5(join("", [for f in fileset("${var.function_path}/src", "**") : filemd5("${var.function_path}/src/${f}")]))
    changes_req = (fileexists("${var.function_path}/build/requirements.txt") ? filemd5("${var.function_path}/src/requirements.txt") : "")
  }
}

data "archive_file" "archive" {
  depends_on = [
    null_resource.copy_source
  ]
  excludes = [
    "__pycache__",
    "venv",
    ".venv"
  ]
  type        = "zip"
  source_dir  = "${var.function_path}/build"
  output_path = "${var.function_path}/output/${var.function_name}.zip"
}
