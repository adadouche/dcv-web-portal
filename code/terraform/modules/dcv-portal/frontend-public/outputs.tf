# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

output "frontend_url" {
  value =  aws_cloudfront_distribution.cloudfront_distribution.domain_name
}
