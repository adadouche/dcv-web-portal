#!/bin/bash

# cd /mnt/c/MyCodeArea/content/dcv-web-portal/code/terraform/modules/dcv-connection-gateway-template-builder-builder/script
# echo '{"region": "eu-west-1", "account_id": "218239986631", "name": "private-connection-gateway"}' | ./get-next-versions.sh
# echo '{"region": "eu-west-1", "account_id": "218239986631", "name": "dcv-npu-dcv-proxy-proxy"}'    | ./get-next-versions.sh

eval "$(jq -r '@sh "export region=\(.region) account_id=\(.account_id) name=\(.name)"')"

current_component=$(aws imagebuilder list-components      --query "componentVersionList  [?starts_with(arn, 'arn:aws:imagebuilder:${region}:${account_id}:component/${name}')].arn"                 --output text | grep -oE "[^/]+$")
current_recipe=$(   aws imagebuilder list-image-recipes   --query "imageRecipeSummaryList[?starts_with(arn, 'arn:aws:imagebuilder:${region}:${account_id}:image-recipe/${name}')].arn"              --output text | grep -oE "[^/]+$")

if [ -z "$current_component" ]; then current_component="1.0.0" ; fi
if [ -z "$current_recipe"    ]; then current_recipe="1.0.0" ; fi

next_component=$(echo $current_component | awk -F. -v OFS=. '{$NF += 1 ; print}')
next_recipe=$(   echo $current_recipe    | awk -F. -v OFS=. '{$NF += 1 ; print}')


if [ -z "$next_component" ]; then next_component="1.0.0" ; fi
if [ -z "$next_recipe"    ]; then next_recipe="1.0.0" ; fi

jq -n \
  --arg current_component "$current_component" \
  --arg current_recipe "$current_recipe" \
  --arg next_component "$next_component" \
  --arg next_recipe "$next_recipe" \
  '{"current_component":$current_component,"current_recipe":$current_recipe,"next_component":$next_component,"next_recipe":$next_recipe}'
