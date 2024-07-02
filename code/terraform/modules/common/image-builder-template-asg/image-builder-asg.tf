# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  # asg_enabled = (local.asg_config != null)
  asg_config  = lookup(var.config.template_content, "autoscaling_group", {})

  tcp_port = lookup(local.asg_config, "tcp_port", -1)
  udp_port = lookup(local.asg_config, "udp_port", -1)

  distinct_ports = (local.udp_port != local.tcp_port ? true : false)

  asg_target_group_arns = (
    local.distinct_ports == false
  ) ? [
    aws_lb_target_group.target_group[0].arn 
  ] : compact([ 
    (local.tcp_port != -1 ? aws_lb_target_group.target_group_tcp[0].arn : null),
    (local.udp_port != -1 ? aws_lb_target_group.target_group_udp[0].arn : null)
  ])
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name              = "${var.env.prefix}-${var.config.template_name}"
  max_size          = local.asg_config.max_size
  min_size          = local.asg_config.min_size
  health_check_type = "ELB"
  desired_capacity  = local.asg_config.min_size

  target_group_arns = local.asg_target_group_arns

  vpc_zone_identifier = var.config.asg_vpc_subnet_ids

  instance_refresh {
    strategy = "Rolling"
    preferences {
      instance_warmup = 300
    }
  }

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = var.config.launch_template_id 
        version            = "$Default"
      }

      override {
        instance_type = "${var.config.template_content.instance_type}"
      }
    }

    instances_distribution {
      # If we "enable spot", then make it 100% spot.
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "lowest-price"
      spot_max_price                           = "" # Empty string is "on-demand price"
    }
  }

  wait_for_capacity_timeout = 0

  tag {
    key   = "Name"
    value = "[${var.env.prefix}] ${var.config.template_name}"    
    propagate_at_launch = true
  }
}

resource "aws_lb_target_group" "target_group_tcp" {
  count                  = (local.distinct_ports && local.tcp_port != -1 ) ? 1 : 0
  name                   = "${var.env.prefix}-${var.config.template_name}-tcp"
  port                   =  local.asg_config.tcp_port
  protocol               = "TCP"
  vpc_id                 = var.config.asg_vpc_id
  preserve_client_ip     = true
  connection_termination = true

  stickiness {
    type    = "source_ip"
    enabled = true
  }

  health_check {
    port                = local.asg_config.health_check_port
    protocol            = "TCP"
    healthy_threshold   = 10
    unhealthy_threshold = 10
  }
}

resource "aws_lb_target_group" "target_group_udp" {
  count                  = (local.distinct_ports && local.udp_port != -1 ) ? 1 : 0
  name                   = "${var.env.prefix}-${var.config.template_name}-udp"
  port                   =  local.asg_config.udp_port
  protocol               = "UDP"
  vpc_id                 = var.config.asg_vpc_id
  preserve_client_ip     = true
  connection_termination = true

  stickiness {
    type    = "source_ip"
    enabled = true
  }

  health_check {
    port                = local.asg_config.health_check_port
    protocol            = "TCP"
    healthy_threshold   = 10
    unhealthy_threshold = 10
  }
}

# if udp port is the same as tcp port, use TCP_UDP protocol instead of 2 target groups
resource "aws_lb_target_group" "target_group" {
  count                  = (local.distinct_ports == false ) ? 1 : 0
  name                   = "${var.env.prefix}-${var.config.template_name}"
  port                   = local.asg_config.tcp_port
  protocol               = "TCP_UDP"
  vpc_id                 = var.config.asg_vpc_id
  preserve_client_ip     = true
  connection_termination = true

  stickiness {
    type    = "source_ip"
    enabled = true
  }

  health_check {
    port                = local.asg_config.health_check_port
    protocol            = "TCP"
    healthy_threshold   = 10
    unhealthy_threshold = 10
  }
}

resource "aws_lb_listener" "listener_tcp" {
  count             = (local.distinct_ports && local.tcp_port != -1 ) ? 1 : 0
  load_balancer_arn = var.config.asg_load_balancer_arn
  port              = local.asg_config.tcp_port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group_tcp[0].arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "listener_udp" {
  count             = (local.distinct_ports && local.udp_port != -1 ) ? 1 : 0
  load_balancer_arn = var.config.asg_load_balancer_arn
  port              = local.asg_config.udp_port
  protocol          = "UDP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group_udp[0].arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "listener" {
  count             = (local.distinct_ports == false ) ? 1 : 0
  load_balancer_arn = var.config.asg_load_balancer_arn
  port              = (local.tcp_port != -1 ? local.tcp_port : local.udp_port)
  protocol          = "TCP_UDP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group[0].arn
    type             = "forward"
  }
}

