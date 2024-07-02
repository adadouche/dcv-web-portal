#!/bin/bash

export target=$1

if [ -z "$target" ] || [ "$target" = "" ] ; then
    echo "$(date) - $PWD - target is empty"
    export TF_DATA_DIR=$PWD/.terraform
    export TF_WORKSPACE="default"
else
    echo "$(date) - $PWD - target set to $target"
    export TF_DATA_DIR=$PWD/.terraform-$target
    export TF_WORKSPACE="$target"
fi

echo "$(date) - $PWD - target=$target - workspace select"
terraform -chdir="$PWD" workspace select "$target" > /dev/null 2>&1

echo "$(date) - $PWD - target=$target - init"
terraform -chdir="$PWD" init > /dev/null 2>&1

start=$(date +%s)
echo "$(date) - $PWD - target=$target - destroy $target started"
tfvars=$PWD/terraform-$target.tfvars
if [ -f "$tfvars" ]; then
    terraform -chdir="$PWD" destroy -auto-approve -lock=false -var-file="$tfvars"
else 
    echo "unable to find tfvars=$tfvars. Destroying anyway without"
    terraform -chdir="$PWD" destroy -auto-approve -lock=false
fi
echo "$(date) - $PWD - target=$target - destroy $target completed! - Elapsed Time: $(($end-$start)) seconds"
