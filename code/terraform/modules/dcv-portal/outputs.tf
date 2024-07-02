# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

output "url" {
  value =  (var.module_network.config.deployment_mode == "public" ?  module.frontend_public[0].frontend_url : module.frontend_private[0].frontend_url)
}
