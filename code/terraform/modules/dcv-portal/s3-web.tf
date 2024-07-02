# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_s3_bucket" "web_content" {
  bucket        = "${var.env.account_id}-${var.env.region}-${var.env.prefix}-web"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "web_content" {
  bucket = aws_s3_bucket.web_content.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "null_resource" "upload_web_content_to_s3" {
  depends_on = [
    data.archive_file.archive_dst
  ]

  triggers = {
    frontend_s3_bucket = "${aws_s3_bucket.web_content.id}"
    frontend_build     = "${local.frontend_src}/dist"
    frontend_src       = "${local.frontend_src}"

    archive_dst        = data.archive_file.archive_dst.output_base64sha256
  }
  
  provisioner "local-exec" {
    when = create
    on_failure = continue
    command = <<-EOT
    aws s3 sync ${self.triggers.frontend_build}/ s3://${self.triggers.frontend_s3_bucket} --exclude "*.js"
    aws s3 sync ${self.triggers.frontend_build}/ s3://${self.triggers.frontend_s3_bucket} --include "*.js" --content-type "application/javascript"
    EOT    
  }

  provisioner "local-exec" {
    when = destroy
    on_failure = continue
    command = <<-EOT
      aws s3 rm s3://${self.triggers.frontend_s3_bucket} --recursive || echo rm failed
    EOT
  }
}