# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  frontend_src = "${abspath(path.module)}/../../../web-content"
}

resource "null_resource" "install_dependencies" {
  triggers = {
    cfg_chksum   = filemd5("${local.frontend_src}/package.json"),
    frontend_src = local.frontend_src
  }

  lifecycle {
      create_before_destroy = true
  }
  
  provisioner "local-exec" {
    when = create
    command = <<-EOT
      cd ${self.triggers.frontend_src}
      npm install
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      cd ${self.triggers.frontend_src}
      rm -rf ./node_modules || echo "rm failed"
    EOT
  }
}

resource "local_file" "generate_config" {  
  depends_on = [
    null_resource.install_dependencies,
  ]

  lifecycle {
    create_before_destroy = true
  }

  filename = "${local.frontend_src}/export/aws-config.js"
  content  = <<EOF
export const region          = "${var.env.region}";

export const project         = "${var.env.project}";
export const application     = "${var.env.application}";
export const environment     = "${var.env.environment}";
export const account_id      = "${var.env.account_id}";
export const prefix          = "${var.env.prefix}";

export const deploymentMode  = "${var.module_dcv.deploymentMode}";
export const useCognitoProxy = ${var.module_dcv.useCognitoProxy};

export const userPoolId           = "${var.module_dcv.userPoolId}";
export const userPoolWebClientId  = "${var.module_dcv.userPoolWebClientId}";
export const identityPoolId       = "${var.module_dcv.identityPoolId}";

export const userPoolEndpoint      = "${var.module_dcv.userPoolEndpoint}";
export const userPoolEndpointProxy = "${var.module_dcv.userPoolEndpointProxy}";

export const identityPoolEndpoint      = "${var.module_dcv.identityPoolEndpoint}";
export const identityPoolEndpointProxy = "${var.module_dcv.identityPoolEndpointProxy}";

export const connectionGatewayLoadBalancerEndpoint     = "${var.module_dcv.connectionGatewayLoadBalancerEndpoint}";
export const connectionGatewayLoadBalancerPort         =  ${var.module_dcv.connectionGatewayLoadBalancerPort};

export const download_links = ${jsonencode(local.dcv_client_downloads_list)};

// ---------------------------------------------------------------------------------------
// waiting for PR to be merged : https://github.com/aws-amplify/amplify-js/pull/13025#
// it will allow the use of the following settings instead of the fetch 'hack' below
// ---------------------------------------------------------------------------------------
export const cognito = {
  identityPoolId: identityPoolId,
  userPoolId: userPoolId,
  userPoolClientId: userPoolWebClientId,

  // identityPoolEndpoint: identityPoolEndpoint,
  // userPoolEndpoint: config.userPoolEndpoint,
};

if (useCognitoProxy) {
  const { fetch: originalFetch } = window;
  window.fetch = async (...args) => {
    let [resource, config] = args;
    let proxy = resource["href"];
    if (resource["href"] === `https://cognito-identity.$${region}.amazonaws.com/`) {
      proxy = window.location.origin + identityPoolEndpointProxy;
    }
    if (resource["href"] === `https://cognito-idp.$${region}.amazonaws.com/`) {
      proxy = window.location.origin + userPoolEndpointProxy;
    }
    if(resource["href"] !== proxy) {
      console.log("fetch " + resource["href"] + " -- > " + proxy);
      resource["href"] = proxy;
    }
    return await originalFetch(...args);
  };
}

// ---------------------------------------------------------------------------------------

EOF
}

resource "null_resource" "generate_config" {
  depends_on = [
    null_resource.install_dependencies,
  ]

  lifecycle {
      create_before_destroy = true
  }  

  triggers = {
    frontend_src = local.frontend_src
    apiEndpoint  = var.module_dcv.apiEndpoint
  }

  provisioner "local-exec" {
    when = create
    command = <<-EOT
      sed "s|apiEndpoint|${self.triggers.apiEndpoint}|g" ${self.triggers.frontend_src}/vite.config.ts.template > ${self.triggers.frontend_src}/vite.config.ts
EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      rm ${self.triggers.frontend_src}/aws-config.js  || echo "rm failed"
      rm ${self.triggers.frontend_src}/vite.config.ts || echo "rm failed"
    EOT
  }
}

data "archive_file" "archive_src" {
  depends_on = [
    null_resource.install_dependencies,
    null_resource.generate_config,
    null_resource.dcv_client_downloads,
    local_file.generate_config,
  ]
  excludes = [
    "dist",
    "node_modules",
    "*.zip"
  ]
  type        = "zip"

  source_dir  = "${local.frontend_src}"
  output_path = "/tmp/frontend_src.zip"
}

resource "null_resource" "build" {
  depends_on = [
    data.archive_file.archive_src
  ]

  lifecycle {
    create_before_destroy = true
  }
  
  triggers = {
    frontend_src       = "${local.frontend_src}"

    generate_config    = local_file.generate_config.content_base64sha256
    archive_src        = data.archive_file.archive_src.output_base64sha256
  }

  provisioner "local-exec" {
    when = create
    command = <<-EOT
      cd ${self.triggers.frontend_src}
      npm run build
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      cd ${self.triggers.frontend_src}
      rm -rf ./dist || echo "rm failed"
      rm -rf /tmp/frontend_src.zip || echo "rm failed"
    EOT
  }
}

data "archive_file" "archive_dst" {
  depends_on = [
    null_resource.build
  ]

  type        = "zip"

  source_dir  = "${local.frontend_src}/dist"
  output_path = "/tmp/frontend_dst.zip"
}
