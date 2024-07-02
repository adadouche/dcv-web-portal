#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

usage() {
    echo ""
    echo "./configure.sh <stack mode> <prefix>"
    echo "  - stack mode : one of the following values: [apps | components]. It will be used to load the configurations values."
    echo "  - prefix     : the resource prefix (for example 'app-epu')"
    echo ""
}

stack_mode=$1

if [[ $stack_mode == "" ]]
then
    echo "Unable to run the script: stack mode is not set";
    usage
    exit 1
fi

stack_modes=(apps components)

prefix=$2

if [[ $prefix == "" ]]
then
    echo "Unable to run the script: prefix is not set";
    usage
    exit 1
fi

if ! [[ ${stack_modes[*]} =~ "$stack_mode" ]]
then
    echo "Unable to run the script: stack mode \"$stack_mode\" is not in [${stack_modes[*]}]";
    usage
    exit 1
fi

if [ "$stack_mode" == "apps" ]
then
    tfstate_path="-state=$SCRIPT_DIR/../../terraform/apps/dcv-portal/terraform.tfstate.d/$prefix/terraform.tfstate"
    jq_path=""
fi

if [ "$stack_mode" == "components" ]
then
    tfstate_path="-state=$SCRIPT_DIR/../../terraform/components/dcv-core/terraform.tfstate.d/$prefix/terraform.tfstate"
    jq_path=".outputs"
fi

echo ""
echo "Loading the configuration from $tfstate_path"
echo ""

region=$(     terraform output $tfstate_path -json | jq -r "$jq_path.env_region.value")

project=$(    terraform output $tfstate_path -json | jq -r "$jq_path.env_project.value")
application=$(terraform output $tfstate_path -json | jq -r "$jq_path.env_application.value")
environment=$(terraform output $tfstate_path -json | jq -r "$jq_path.env_environment.value")
account_id=$( terraform output $tfstate_path -json | jq -r "$jq_path.env_account_id.value")
prefix=$(     terraform output $tfstate_path -json | jq -r "$jq_path.env_prefix.value")

deploymentMode=$(     terraform output $tfstate_path -json | jq -r "$jq_path.env_deploymentMode.value")
userPoolId=$(         terraform output $tfstate_path -json | jq -r "$jq_path.portal_userPoolId.value")
userPoolWebClientId=$(terraform output $tfstate_path -json | jq -r "$jq_path.portal_userPoolWebClientId.value")
userPoolEndpoint=$(   terraform output $tfstate_path -json | jq -r "$jq_path.userPoolEndpoint.value")
identityPoolId=$(     terraform output $tfstate_path -json | jq -r "$jq_path.portal_identityPoolId.value")
apiEndpoint=$(        terraform output $tfstate_path -json | jq -r "$jq_path.portal_apiEndpoint.value")

connectionGatewayLoadBalancerEndpoint=$(terraform output $tfstate_path -json | jq -r "$jq_path.portal_connectionGatewayLoadBalancerEndpoint.value")
connectionGatewayLoadBalancerPort=$(    terraform output $tfstate_path -json | jq -r "$jq_path.portal_connectionGatewayLoadBalancerPort.value")

echo "----------------------------------------------------------------------------"
echo ""
echo "Generated configuration:"
echo ""
echo "----------------------------------------------------------------------------"
echo ""
echo "$SCRIPT_DIR/../src/aws/aws-config.js:"
echo ""
echo "----------------------------------------------------------------------------"

cat <<EOF > $SCRIPT_DIR/../aws-config.js
export const region          = "$region";
export const project         = "$project";
export const application     = "$application";
export const environment     = "$environment";
export const account_id      = "$account_id";
export const prefix          = "$prefix";

export const deploymentMode      = "$deploymentMode";

export const userPoolId          = "$userPoolId";
export const userPoolWebClientId = "$userPoolWebClientId";
export const userPoolEndpoint    = "$userPoolEndpoint";
export const identityPoolId      = "$identityPoolId";

export const connectionGatewayLoadBalancerEndpoint     = "$connectionGatewayLoadBalancerEndpoint";
export const connectionGatewayLoadBalancerPort         =  $connectionGatewayLoadBalancerPort;
EOF

more $SCRIPT_DIR/../src/aws/aws-config.js

echo "----------------------------------------------------------------------------"
echo ""
echo "$SCRIPT_DIR/../vite.config.ts:"
echo ""
echo "----------------------------------------------------------------------------"

sed "s|apiEndpoint|$apiEndpoint|g" $SCRIPT_DIR/../vite.config.ts.template > $SCRIPT_DIR/../vite.config.ts

more $SCRIPT_DIR/../vite.config.ts

echo ""
echo "----------------------------------------------------------------------------"