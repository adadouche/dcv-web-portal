# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

module "lambda_image_builder_run_pipeline" {
  source     = "./lambdas/image-builder-run-pipeline"
  env        = var.env
}

module "lambda_image_builder_update_tags" {
  source     = "./lambdas/image-builder-update-tags"
  env        = var.env
}

module "lambda_asg_instance_refresh" {
  source     = "./lambdas/asg-instance-refresh"
  env        = var.env
}