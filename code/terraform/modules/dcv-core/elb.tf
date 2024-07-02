# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_lb" "load_balancer" {
  name                             = "${var.env.prefix}"
  load_balancer_type               = "network"
  ip_address_type                  = "ipv4"
  internal                         = (var.module_network.config.deployment_mode == "public" ? false : true )
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false
  desync_mitigation_mode           = "strictest"
  security_groups                  = [aws_security_group.elb_sg.id]

  subnets = (var.module_network.config.deployment_mode == "public" ? var.module_network.vpc_subnets_public.*.id : var.module_network.vpc_subnets_private.*.id)
}
