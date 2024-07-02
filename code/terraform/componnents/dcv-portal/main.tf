# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

terraform {
  required_version = ">= 1.3.0, < 2.0.0"  
  # required_version = "~> 1.3.0"

  required_providers {
    aws = {
      # version = "~> 4.14"
      version = "~> 5.22.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = local.env.region
  default_tags {
    tags = local.env.tags
  }
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
  default_tags {
    tags = local.env.tags
  }
}

data "terraform_remote_state" "core" {
  backend = "local"

  config = {
    path = "../core/terraform.tfstate.d/${terraform.workspace}/terraform.tfstate"
  }
}

data "terraform_remote_state" "dcv" {
  backend = "local"

  config = {
    path = "../dcv-core/terraform.tfstate.d/${terraform.workspace}/terraform.tfstate"
  }
}

locals {
  state = {
    core = data.terraform_remote_state.core.outputs
    dcv = data.terraform_remote_state.dcv.outputs
  }
  module_network          = local.state.core.module_network
  module_encryption       = local.state.core.module_encryption
  module_authentication   = local.state.core.module_authentication
  
  env                   = local.state.core.env

  authentication_config = local.state.core.authentication_config
  network_config        = local.state.core.network_config
  dcv_config            = local.state.core.dcv_config

  module_dcv            = local.state.dcv.module_dcv
}

###############################################################################

resource "local_file" "template_builder_vars" {
  filename = "../dcv-templates/terraform-${local.env.project}.tfvars"
  content  = <<EOF
project     = "${local.env.project}"
application = "${local.env.application}"
environment = "${local.env.environment}"
prefix      = "${local.env.prefix}"
region      = "${local.env.region}"
account_id  = "${local.env.account_id}"

kms_key_id                            = "${local.module_encryption.kms_key.id}"

vpc_subnet_ids_image_builder          = ["${local.module_network.vpc_image_builder_subnet.id}"]
vpc_subnet_ids_workstation            = ${jsonencode(local.module_network.vpc_subnets_private.*.id)}

vpc_security_group_ids_image_builder  = ["${local.module_dcv.vpc_security_groups["image-builder"].id}"]
vpc_security_group_ids_workstation    = ["${local.module_dcv.vpc_security_groups["workstations-instances"].id}", "${local.module_dcv.vpc_security_groups["vpce"].id}"]

dcv_lambda_update_tags_function_name  = "${local.module_dcv.dcv_lambdas["image-builder-update-tags"].lambda.function_name}"
dcv_lambda_run_pipeline_function_name = "${local.module_dcv.dcv_lambdas["image-builder-run-pipeline"].lambda.function_name}"
EOF
}


