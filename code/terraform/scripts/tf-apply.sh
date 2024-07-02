#!/bin/bash

export target=$1

if [ -z "$target" ] || [ "$target" = "" ] ; then
    echo "$(date) - $PWD - target is empty"
    export TF_DATA_DIR=$PWD/.terraform
    export TF_WORKSPACE="default"

    tfvars=$PWD/terraform.tfvars
else
    echo "$(date) - $PWD - target set to $target"
    export TF_DATA_DIR=$PWD/.terraform-$target
    export TF_WORKSPACE="$target"

    tfvars=$PWD/terraform-$target.tfvars
fi

echo "$(date) - $PWD - target=$target - init -upgrade"
terraform -chdir="$PWD" init -upgrade > /dev/null 2>&1

echo "$(date) - $PWD - target=$target - workspace new"
terraform -chdir="$PWD" workspace new    -lock=false "$target" > /dev/null 2>&1

echo "$(date) - $PWD - target=$target - workspace select"
terraform -chdir="$PWD" workspace select             "$target" > /dev/null 2>&1

start=$(date +%s)
echo "$(date) - $PWD - target=$target - apply $target started"
if [ -f "$tfvars" ] ; then
    terraform -chdir="$PWD" apply -auto-approve -lock=false -var-file="$tfvars"
elif [ "$TF_WORKSPACE" = "defaukt"] ; then
    terraform -chdir="$PWD" apply -auto-approve -lock=false
else
    echo "$(date) - $PWD - unable to find target tfvars $tfvars. Exiting"
fi

end=$(date +%s)
echo "$(date) - $PWD - target=$target - apply $target completed! - Elapsed Time: $(($end-$start)) seconds"