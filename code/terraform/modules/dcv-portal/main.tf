# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [ aws.current , aws.us-east-1]
    }
  }
}

module "frontend_public" {
  count  = (var.module_network.config.deployment_mode == "public" ? 1 : 0)

  depends_on = [
    null_resource.install_dependencies,
    null_resource.generate_config,
    null_resource.build,
    null_resource.upload_web_content_to_s3,
  ]

  source = "./frontend-public"
  env    = var.env
   
  config = merge ({
    "web_content_bucket_id"          = aws_s3_bucket.web_content.id
    "web_content_bucket_domain_name" = aws_s3_bucket.web_content.bucket_regional_domain_name
    "vpc_security_groups"            = var.module_dcv.vpc_security_groups
  })

  module_encryption = var.module_encryption
  module_network    = var.module_network
  module_dcv        = var.module_dcv

  providers = {
    aws.current   = aws.current
    aws.us-east-1 = aws.us-east-1
  }
}

module "frontend_private" {
  count  = (var.module_network.config.deployment_mode == "public" ? 0 : 1)

  depends_on = [
    null_resource.install_dependencies,
    null_resource.generate_config,
    null_resource.build,
    null_resource.upload_web_content_to_s3,
  ]

  source = "./frontend-private"
  env    = var.env
   
  config = merge ({
      "template_config_folder"         = var.module_dcv.config.template_config_folder
      "web_content_bucket_id"          = aws_s3_bucket.web_content.id
      "web_content_bucket_domain_name" = aws_s3_bucket.web_content.bucket_regional_domain_name
      "api_endpoint"                   = var.module_dcv.apiEndpoint
    },
    var.module_dcv.config
  )

  module_encryption = var.module_encryption
  module_network    = var.module_network
  module_dcv        = var.module_dcv
}