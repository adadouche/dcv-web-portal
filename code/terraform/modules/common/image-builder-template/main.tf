# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {

  os_family   = var.config.template_default_os_config[var.config.template_content.os_name].os_family
  os_version  = var.config.template_default_os_config[var.config.template_content.os_name].os_version
  os_platform = var.config.template_default_os_config[var.config.template_content.os_name].os_platform

  enable_hibernation = lookup(var.config.template_content, "enable_hibernation", false)

  policies_managed = distinct ( concat ( 
    var.config.template_default_config.default_policies_managed,
    var.config.template_content.policies_managed
  ) )

  policies_statements_template = distinct ( concat (
    var.config.template_content.policies_inline
  ) )

  policies_statements_default = distinct ( concat (  
    var.config.template_default_config.default_policies_inline
  ) )

  policies_inline_default = jsonencode({
    Version   = "2012-10-17"
    Statement = local.policies_statements_default
  })

  policies_inline_template = jsonencode({
    Version   = "2012-10-17"
    Statement = local.policies_statements_template
  })

  template_image_id = ( 
    length(data.aws_ami_ids.template_custom_ami.ids) == 0 
    ? 
    data.aws_ami.template_base_ami.id 
    : 
    data.aws_ami_ids.template_custom_ami.ids[0] 
  )

  template_image_source = ( 
    length(data.aws_ami_ids.template_custom_ami.ids) == 0 
    ? 
    "base" : "custom"
  )

  template_description = "Default LT for [${var.env.prefix}-${var.config.template_name}] with [${local.template_image_source}] AMI [${local.template_image_id}]"

  recipe_components_default_aws = merge ({ 
    for key, value in var.config.template_default_os_config : 
    key => distinct ( concat ( 
      lookup(var.config.template_default_config.default_components_aws, key, []) , 
      lookup(var.config.template_default_config.default_components_aws, lower("${value.os_family}-${value.os_version}"), []),
      lookup(var.config.template_default_config.default_components_aws, lower(value.os_family), []), 
      lookup(var.config.template_default_config.default_components_aws, lower(value.os_platform), [])  
    ) )
  })

  recipe_components_default_custom = merge ({ 
    for key, value in var.config.template_default_os_config : 
    key => distinct ( concat ( 
      lookup(var.config.template_default_config.default_components_custom, key, []) , 
      lookup(var.config.template_default_config.default_components_custom, lower("${value.os_family}-${value.os_version}"), []),
      lookup(var.config.template_default_config.default_components_custom, lower(value.os_family), []), 
      lookup(var.config.template_default_config.default_components_custom, lower(value.os_platform), [])  
    ) )
  })

  recipe_components_shortlist = distinct ( concat ( 
    [ for value in distinct ( concat (lookup(var.config.template_content, "components_aws"                                     , [])) ) : "${value}" ], 
    [ for value in distinct ( concat (lookup(local.recipe_components_default_aws   , lower(var.config.template_content.os_name), [])) ) : "${value}" ], 
    [ for value in distinct ( concat (lookup(var.config.template_content, "components_custom"                                  , [])) ) : "${value}" ], 
    [ for value in distinct ( concat (lookup(local.recipe_components_default_custom, lower(var.config.template_content.os_name), [])) ) : "${value}" ], 
  ) )

  recipe_components = distinct ( concat ( 
    [ for value in distinct ( concat (lookup(var.config.template_content, "components_aws"                                     , [])) ) : "arn:aws:imagebuilder:${var.env.region}:aws:component/${value}/x.x.x" ], 
    [ for value in distinct ( concat (lookup(local.recipe_components_default_aws   , lower(var.config.template_content.os_name), [])) ) : "arn:aws:imagebuilder:${var.env.region}:aws:component/${value}/x.x.x" ], 
    [ for value in distinct ( concat (lookup(var.config.template_content, "components_custom"                                  , [])) ) : "arn:aws:imagebuilder:${var.env.region}:${var.env.account_id}:component/${replace("${var.env.prefix}-${value}", ".", "-")}/x.x.x" ], 
    [ for value in distinct ( concat (lookup(local.recipe_components_default_custom, lower(var.config.template_content.os_name), [])) ) : "arn:aws:imagebuilder:${var.env.region}:${var.env.account_id}:component/${replace("${var.env.prefix}-${value}", ".", "-")}/x.x.x" ], 
  ) )

  tags_default = { 
    "components_managed" : substr( join(",", local.recipe_components_shortlist), 0, 254),
    "policies_managed"   : substr( join(",", local.policies_managed), 0, 254),
    "os_family"          : local.os_family
    "os_version"         : local.os_version
    "os_platform"        : local.os_platform
    "template_type"      : var.config.template_content.template_type
  }

  tags_instance = merge (
    lookup(var.config, "tags_instance", {}) ,
    local.tags_default
  )

  tags_template = merge (
    lookup(var.config, "tags_template", {}) ,
    local.tags_default
  )
}

data "aws_ami" "template_base_ami" {
  owners = ["amazon", "aws-marketplace", "microsoft"]
  most_recent = true
  filter {
    name   = "name"
    values = [
      "${var.config.template_content.os_base_ami_regexp}"
    ]
  }
}

data "aws_ami_ids" "template_custom_ami" {
  owners = ["self"]
  sort_ascending  = false
  filter {
    name   = "name"
    values = [
      "${var.env.prefix}-${var.config.template_name}-*"
    ]
  }
}