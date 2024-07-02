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

data "terraform_remote_state" "core" {
  backend = "local"

  config = {
    path = "../core/terraform.tfstate.d/${terraform.workspace}/terraform.tfstate"
  }
}

locals {
  state = {
    core = data.terraform_remote_state.core.outputs
  }
  module_network          = local.state.core.module_network
  module_encryption       = local.state.core.module_encryption
  module_authentication   = local.state.core.module_authentication
  
  env                   = local.state.core.env

  authentication_config = local.state.core.authentication_config
  network_config        = local.state.core.network_config
  dcv_config            = local.state.core.dcv_config
}
