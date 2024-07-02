# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

output "frontend_url" {
  value =  var.module_dcv.load_balancer.dns_name
}
