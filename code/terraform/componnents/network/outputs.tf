# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

output "vpc_dcv_existing_id" {
  value = aws_vpc.vpc.id
}
output "vpc_dcv_existing_public_subnet_ids" {
  value = aws_subnet.subnet_public.*.id
}
output "vpc_dcv_existing_private_subnet_ids" {
  value  = aws_subnet.subnet_private.*.id
}
output "vpc_image_builder_existing_id" {
  value = aws_vpc.ib_vpc.id
}
output "vpc_image_builder_existing_public_subnet_id" {
  value  = aws_subnet.ib_subnet_public.id
}