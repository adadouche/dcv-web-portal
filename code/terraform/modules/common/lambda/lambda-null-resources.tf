# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# Deleting lambda vpc config to avoid eni getting stuck when destroying resources
resource "null_resource" "on_destroy_lambda" {
  depends_on  = [
    aws_lambda_function.lambda_function
  ]
  
  triggers = {
    region        = var.env.region
    function_path = var.function_path
    function_name = aws_lambda_function.lambda_function.function_name
  }
  # requried to link it with resource and allow destroy
  provisioner "local-exec" {
    when = create
    on_failure = continue
    command = <<-EOT
      # region=${self.triggers.region}
      # function_name=${self.triggers.function_name}
    EOT
  }
  
  provisioner "local-exec" {
    when = destroy
    on_failure = continue
    command = <<-EOT
      rm -rf ${self.triggers.function_path}/build  || echo "rm failed"
      rm -rf ${self.triggers.function_path}/output || echo "rm failed"

      region=${self.triggers.region}
      function_name=${self.triggers.function_name}
      
      aws lambda update-function-configuration --region $region --function-name $function_name --vpc-config SubnetIds=[],SecurityGroupIds=[] > /dev/null

    EOT
  }
}
