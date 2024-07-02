# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

terraform {
  required_version = ">= 1.7.0, < 2.0.0" 
  required_providers {
    aws = {
      version = "~> 5.35.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
  default_tags {
    tags = local.tags
  }
}

# Helpers references
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

# from https://stackoverflow.com/questions/46763287/i-want-to-identify-the-public-ip-of-the-terraform-execution-environment-and-add
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  tags        = {
    "project"     = var.project
    "application" = var.application
    "environment" = var.environment
    "last_updated_by"  = "Last updated by ${var.created_by_email} via Terraform"
  }  
  env = {
    project         = var.project
    region          = var.region
    application     = var.application
    environment     = var.environment
    account_id      = ( var.account_id == null ? data.aws_caller_identity.current.account_id : var.account_id )
    prefix          = var.prefix
    tags            = local.tags
  }
  
  #lookup is not working here for some odd reasons. Boolean?
  use_existing_vpcs = (var.network_config.use_existing_vpcs        == null ? false : var.network_config.use_existing_vpcs)
  use_cognito_proxy = (var.authentication_config.use_cognito_proxy == null ? true  : var.authentication_config.use_cognito_proxy) 

  default_network_config = {
    deployment_mode = "public"

    ip_allow_list_enabled = true
    ip_allow_list         = ["${chomp(data.http.myip.response_body)}/32"]
    
    use_existing_vpcs  = local.use_existing_vpcs

    vpc_dcv_cidr_block        = "192.168.0.0/16"
    vpc_dcv_subnets_az_count  = 2 
    vpc_dcv_subnets_cidr_bits = 4

    vpc_image_builder_cidr_block        = "192.168.1.0/24"
    vpc_image_builder_subnets_cidr_bits = 2    
  }

  default_authentication_config = {
    use_cognito_proxy = local.use_cognito_proxy
    admin_group_name  = "admin"
    admin_user        = {
      admin_login              = "admin"
      admin_full_name          = "Administrator User"
      admin_email              = var.created_by_email
      admin_temporary_password = "TempPassw0rd!"
    }
  }

  default_dcv_config = {
    connection_gateway_config = {
      udp_port                = 8443
      tcp_port                = 8443
      health_check_port       = 8989
    }
    dcv_server_config = {
      udp_port                = 8443
      tcp_port                = 8443
      health_check_port       = 8989   
    }
  }

  network_config = merge (
    local.default_network_config,
    {
       # from https://github.com/hashicorp/terraform/issues/31823#issuecomment-1272373600
       # to remove null values from the object which will override default values
      for k, v in var.network_config : k => v if v != null
    }
  )

  authentication_config = merge (
    local.default_authentication_config,
    {
       # from https://github.com/hashicorp/terraform/issues/31823#issuecomment-1272373600
       # to remove null values from the object which will override default values
      for k, v in var.authentication_config : k => v if v != null
    }
  )

  dcv_config = merge (
    local.default_dcv_config,
    {
       # from https://github.com/hashicorp/terraform/issues/31823#issuecomment-1272373600
       # to remove null values from the object which will override default values
      for k, v in var.dcv_config : k => v if v != null
    }   
  )
}
###############################################################################

module "encryption" {
  source     = "../../modules/core-encryption"
  env        = local.env
}

module "network" {
  source     = "../../modules/core-network"
  env        = local.env

  config     = local.network_config
  
  module_encryption = module.encryption

  depends_on  = [
    module.encryption
  ]
}

module "authentication" {
  source     = "../../modules/core-authentication"
  env        = local.env

  config     = local.authentication_config
  
  module_encryption = module.encryption

  depends_on  = [
    module.encryption
  ]  
}

###############################################################################

module "dcv" {
  source     = "../../modules/dcv-core"
  env        = local.env
  
  config     = merge (
    local.dcv_config,
    {
      template_config_folder = "${abspath(path.module)}/config"
    }
  )

  module_network        = module.network
  module_encryption     = module.encryption
  module_authentication = module.authentication

  depends_on  = [
    module.network,
    module.encryption,
    module.authentication
  ]
}

###############################################################################

module "dcv_portal" {
  source     = "../../modules/dcv-portal"
  env        = local.env
  
  module_encryption     = module.encryption
  module_network        = module.network
  module_dcv            = module.dcv
  
  providers = {
    aws.current   = aws
    aws.us-east-1 = aws.us-east-1
  }

  config = {
    config_folder = "${abspath(path.module)}/config"
  }

  depends_on  = [
    module.dcv,
  ]    
}

###############################################################################

locals {
  tfvar_path = "${abspath(path.module)}/../dcv-templates"
  tfvar_file = "terraform.tfvars"
  tfvar      = "${local.tfvar_path}/${local.tfvar_file}"
}

resource "local_file" "template_builder_vars" {  
  depends_on  = [
    module.dcv,
  ]

  lifecycle {
    create_before_destroy = true
  }

  filename = "${local.tfvar}"
  content  = <<EOF
project     = "${local.env.project}"
application = "${local.env.application}"
environment = "${local.env.environment}"
prefix      = "${local.env.prefix}"
region      = "${local.env.region}"
account_id  = "${local.env.account_id}"

config = {
  kms_key_id                            = "${module.encryption.kms_key.id}"

  vpc_subnet_id_image_builder           = "${module.network.vpc_image_builder_subnet.id}"
  vpc_subnet_ids_workstation            = ${jsonencode(module.network.vpc_subnets_private.*.id)}

  vpc_security_group_ids_image_builder  = ["${module.dcv.vpc_security_groups["image-builder"].id}"]
  vpc_security_group_ids_workstation    = ["${module.dcv.vpc_security_groups["workstations-instances"].id}", "${module.dcv.vpc_security_groups["vpce"].id}"]

  dcv_lambda_update_tags_function_name  = "${module.dcv.dcv_lambdas["image-builder-update-tags"].lambda.function_name}"
  dcv_lambda_run_pipeline_function_name = "${module.dcv.dcv_lambdas["image-builder-run-pipeline"].lambda.function_name}"

  image_builder_bucket_download  = "${module.dcv.image_builder_bucket_download.id}"
  image_builder_bucket_pipeline  = "${module.dcv.image_builder_bucket_pipeline.id}"
  image_builder_instance_profile = "${module.dcv.image_builder_instance_profile.name}"
}
EOF
}

resource "null_resource" "template_builder_vars" {
  depends_on  = [
    local_file.template_builder_vars
  ]
  
  lifecycle {
    create_before_destroy = true
  }

  triggers = {
    path   = "${local.tfvar_path}"
    file   = "${local.tfvar_file}"
    prefix = "${local.env.prefix}"
    chksum = local_file.template_builder_vars.content_md5
  }
  # requried to link it with resource and allow destroy
  provisioner "local-exec" {
    when = create
    on_failure = continue
    command = <<-EOT
      cd "${self.triggers.path}"
      cp "${self.triggers.file}" "terraform-${self.triggers.prefix}.tfvars" 
    EOT
  }
  
  # provisioner "local-exec" {
  #   when = destroy
  #   on_failure = continue
  #   command = <<-EOT
  #     cd "${self.triggers.path}"
  #     rm "${self.triggers.file}"                    || echo "rm failed"
  #     rm "terraform-${self.triggers.prefix}.tfvars" || echo "rm failed"
  #   EOT
  # }
}