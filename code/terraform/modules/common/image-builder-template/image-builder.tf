# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# Define the image recipe
resource "aws_imagebuilder_image_recipe" "image_recipe" {
  depends_on   = [
    aws_launch_template.launch_template,
  ]
  name        = "${var.env.prefix}-${var.config.template_name}"
  description = "[Recipe] ${var.config.template_name} ${var.config.template_content.template_type}"
  
  parent_image = data.aws_ami.template_base_ami.id
  version      = "1.0.0"
  
  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      parent_image
    ]
  }

  block_device_mapping {
    device_name = (local.os_family == "amazon-linux" ? "/dev/xvda" : "/dev/sda1")
    ebs {
      delete_on_termination = true
      encrypted             = true
      kms_key_id  = "arn:aws:kms:${var.env.region}:${var.env.account_id}:key/${var.config.kms_key_id}"
      volume_size = var.config.template_content.volume_size
      volume_type = var.config.template_content.volume_type
      iops        = var.config.template_content.volume_iops
      throughput  = var.config.template_content.volume_throughput 
    }
  }

  dynamic "component" {
    for_each = local.recipe_components
    content {
      component_arn = "${component.value}"
    }
  }
}

# Define the image pipeline infrastructure
resource "aws_imagebuilder_infrastructure_configuration" "infrastructure_configuration" {
  name        = "${var.env.prefix}-${var.config.template_name}"
  description = "[Infrastructure Configuration] ${var.config.template_name} ${var.config.template_content.template_type}"

  instance_types = [var.config.template_default_config.image_builder_instance_type]
  instance_profile_name = var.config.image_builder_instance_profile
  terminate_instance_on_failure = true

  subnet_id          = var.config.vpc_subnet_id_image_builder
  security_group_ids = var.config.vpc_security_group_ids_image_builder

  logging {
    s3_logs {
      s3_bucket_name = var.config.image_builder_pipeline_logs
      s3_key_prefix  = "pipeline-logs"
    }
  }
}

# Define distribution settings
resource "aws_imagebuilder_distribution_configuration" "distribution_configuration" {
  name        = "${var.env.prefix}-${var.config.template_name}"
  description = "[Distribution Configuration] ${var.config.template_name} ${var.config.template_content.template_type}"

  # lifecycle {
  #   create_before_destroy = false
  # }

  distribution {
    region = var.env.region
      
    ami_distribution_configuration {
      name       = "${var.env.prefix}-${var.config.template_name}-{{ imagebuilder:buildDate }}"
      kms_key_id = var.config.kms_key_id
      ami_tags   = var.env.tags
    }

    launch_template_configuration {
      launch_template_id = aws_launch_template.launch_template.id
      default            = true  
    }
  }
}

# Define the pipeline
resource "aws_imagebuilder_image_pipeline" "image_pipeline" {
  name        = "${var.env.prefix}-${var.config.template_name}"
  description = "[Image Builder Pipeline] ${var.config.template_name} ${var.config.template_content.template_type}"

  image_recipe_arn                 = aws_imagebuilder_image_recipe.image_recipe.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.distribution_configuration.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.infrastructure_configuration.arn

  enhanced_image_metadata_enabled = false

  lifecycle {
    create_before_destroy = false
  }
  
  image_tests_configuration {
    image_tests_enabled = false
  }

  schedule {
    pipeline_execution_start_condition = "EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"
    schedule_expression                = var.config.template_default_config.image_builder_run_schedule
  }

  depends_on = [
    aws_imagebuilder_image_recipe.image_recipe,
    aws_imagebuilder_distribution_configuration.distribution_configuration,
    aws_imagebuilder_infrastructure_configuration.infrastructure_configuration,
  ]
}

# define a lambda invocation to triggered the pipeline on deployment
resource  "aws_lambda_invocation" "build_image" {
  function_name = var.config.dcv_lambda_run_pipeline_function_name
  
  depends_on = [
    aws_imagebuilder_image_pipeline.image_pipeline
  ]

  triggers = {
    "image_pipeline_date_updated"      = aws_imagebuilder_image_pipeline.image_pipeline.date_updated
    "image_infra_date_updated"         = aws_imagebuilder_infrastructure_configuration.infrastructure_configuration.date_updated
    "image_recipe_date_created"        = aws_imagebuilder_image_recipe.image_recipe.date_created
  }

  input = jsonencode(
    {
      "image_pipeline_arn" : "${aws_imagebuilder_image_pipeline.image_pipeline.arn}"
      "apply_date"         : "${aws_imagebuilder_image_pipeline.image_pipeline.date_updated}"
    }
  )
}

resource "aws_cloudwatch_event_rule" "cloudwatch_event_rule" {
  name          = "${var.env.prefix}-upd-lt-${var.config.template_name}"
  description   = "Rule triggered when a workstation AMI and Launch Template are successfully built by Image Builder"
  event_pattern = jsonencode(
    {
      "source": ["aws.ec2"],
      "detail-type": ["AWS API Call via CloudTrail"],
      "detail": {
        "eventName": ["ModifyLaunchTemplate"],
        "userAgent": ["imagebuilder.amazonaws.com"],
        "requestParameters": {
          "ModifyLaunchTemplateRequest": {
            "LaunchTemplateId": [aws_launch_template.launch_template.id]
          }
        },
        "responseElements": {
          "ModifyLaunchTemplateResponse": {
            "launchTemplate": {
              "launchTemplateId": [aws_launch_template.launch_template.id]
            }
          }
        }
      }
    }  
  )
}

resource "aws_cloudwatch_event_target" "cloudwatch_event_target" {
  rule     = aws_cloudwatch_event_rule.cloudwatch_event_rule.name
  arn      = "arn:aws:lambda:${var.env.region}:${var.env.account_id}:function:${var.config.dcv_lambda_update_tags_function_name}"

  input = <<EOF
{"tag": "ui", "value": "show", "launchTemplateIds" : ${jsonencode([aws_launch_template.launch_template.id] )} }
EOF
}

resource "aws_lambda_permission" "instance_refresh_function_invocation" {
  statement_id  = "AllowExecutionFromEventBridge-upd-tags-${var.config.template_name}"
  action        = "lambda:InvokeFunction"
  function_name = var.config.dcv_lambda_update_tags_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudwatch_event_rule.arn
}
