# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_ssm_parameter" "dcv_endpoint" {
  depends_on = [
    # module.api
    aws_api_gateway_stage.api_gateway_stage,
    module.dcv_parent_resource.api_gateway_resource
  ]
  name      = "/${var.env.prefix}/dcv-api-endpoint"
  type      = "String"
  value     = "${aws_api_gateway_stage.api_gateway_stage.invoke_url}/${module.dcv_parent_resource.api_gateway_resource.path_part}"
}

resource "aws_ssm_parameter" "dcv_session_name" {
  name      = "/${var.env.prefix}/dcv-session-name"
  type      = "String"
  value     = "console"
}

resource "aws_ssm_parameter" "dcv_session_type" {
  name      = "/${var.env.prefix}/dcv-session-type"
  type      = "String"
  value     = "console"
}

resource "aws_ssm_parameter" "dcv_connection_gateway_tcp_port" {
  name      = "/${var.env.prefix}/dcv-connection-gateway/tcp-port"
  type      = "String"
  value     = "${var.config.connection_gateway_config.tcp_port}"
}

resource "aws_ssm_parameter" "dcv_connection_gateway_udp_port" {
  name      = "/${var.env.prefix}/dcv-connection-gateway/udp-port"
  type      = "String"
  value     = "${var.config.connection_gateway_config.udp_port}"
}

resource "aws_ssm_parameter" "dcv_connection_gateway_health_check_port" {
  name      = "/${var.env.prefix}/dcv-connection-gateway/health-check-port"
  type      = "String"
  value     = "${var.config.connection_gateway_config.health_check_port}"
}

resource "aws_ssm_parameter" "dcv_server_tcp_port" {
  name      = "/${var.env.prefix}/dcv-server/tcp-port"
  type      = "String"
  value     = "${var.config.dcv_server_config.tcp_port}"
}

resource "aws_ssm_parameter" "dcv_server_udp_port" {
  name      = "/${var.env.prefix}/dcv-server/udp-port"
  type      = "String"
  value     = "${var.config.dcv_server_config.udp_port}"
}

resource "aws_ssm_parameter" "dcv_server_health_check_port" {
  name      = "/${var.env.prefix}/dcv-server/health-check-port"
  type      = "String"
  value     = "${var.config.dcv_server_config.health_check_port}"
}
