# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# Define the launch template that will be used to launch ALS instance based on the images generated from the pipeline
resource "aws_launch_template" "launch_template" {
  name = "${var.env.prefix}-${var.config.template_name}"
  
  # IMPORTANT:THIS IMAGE ID is just to avoid the first deployment to fail the very first time (i.e. empty account).
  # the real image id for this launch template will be updated automatically when the image builder pipeline runs
  image_id    = local.template_image_id
  description = local.template_description
  
  update_default_version = true
  
  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.id
  }

  instance_type = var.config.template_content.instance_type

  # root volume
  block_device_mappings {
    device_name = (local.os_family == "amazon-linux" ? "/dev/xvda" : "/dev/sda1")
    ebs {
      encrypted   = true
      kms_key_id  = "arn:aws:kms:${var.env.region}:${var.env.account_id}:key/${var.config.kms_key_id}"
      volume_size = var.config.template_content.volume_size
      volume_type = var.config.template_content.volume_type
      iops        = var.config.template_content.volume_iops
      throughput  = var.config.template_content.volume_throughput 
    }
  }

  monitoring {
    enabled = true
  }
  
  hibernation_options {
    configured = local.enable_hibernation
  }  

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
    http_put_response_hop_limit = 1
  }

  network_interfaces {
    subnet_id             = var.config.vpc_subnet_ids_target[0]
    security_groups       = var.config.vpc_security_group_ids_target
    delete_on_termination = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge (
      var.env.tags,
      local.tags_instance
    )
  }

  tags = merge (
    var.env.tags,
    local.tags_template,
    {"ui" : length(data.aws_ami_ids.template_custom_ami.ids) == 0 ? "hide" : "show"}
  )

  user_data = base64encode(templatefile("${var.config.template_config_folder}/user-data/${var.config.template_content.template_type}-config.${lower(local.os_platform)}", {
    project     = var.env.project
    application = var.env.application
    environment = var.env.environment
    prefix      = var.env.prefix
    region      = var.env.region
    account_id  = var.env.account_id
  }))  
}
