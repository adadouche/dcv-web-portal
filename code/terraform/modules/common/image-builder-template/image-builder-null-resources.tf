# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# Canceling all image build when destroying resources
resource "null_resource" "on_destroy_image_pipeline" {
  depends_on  = [
    aws_imagebuilder_image_pipeline.image_pipeline,
    aws_imagebuilder_image_recipe.image_recipe,
    aws_imagebuilder_distribution_configuration.distribution_configuration
  ]
  
  triggers = {
    region        = var.env.region
    pipeline_arn  = aws_imagebuilder_image_pipeline.image_pipeline.arn    
  }
  
  # requried to link it with resource and allow destroy
  provisioner "local-exec" {
    when = create
    on_failure = continue
    command = <<-EOT
      # region=${self.triggers.region}
      # pipeline_arn=${self.triggers.pipeline_arn}
    EOT
  }
  
  provisioner "local-exec" {
    when = destroy
    on_failure = continue
    command = <<-EOT
      region=${self.triggers.region}
      pipeline_arn=${self.triggers.pipeline_arn}

      build=$(aws imagebuilder list-image-pipeline-images --image-pipeline-arn $pipeline_arn --query "imageSummaryList[].{arn: arn, status: state.status}[?status == 'BUILDING'].arn" --output text)

      for arn in $build; do
          aws imagebuilder cancel-image-creation --image-build-version-arn $arn
          sleep 2
          aws imagebuilder delete-image --image-build-version-arn $arn
      done
    EOT
  }
}
