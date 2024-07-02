#!/bin/bash

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

sudo yum update -y -q

sudo yum install -y -q jq
sudo yum install -y -q curl

sudo yum install -y -q awscli 
sudo yum install -y -q terraform
sudo yum install -y -q unzip 

sudo yum install python3.11 -y -q
sudo yum install python3-pip -y -q

sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 2

npm cache clean -f
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash # need to reopen the terminal after

bash # to open a new env

nvm install 20

current_version=$(node -v)
current_version="${current_version:1}"

nvm alias default node $current_version

npm install -g npm@10.3.0
npm install -g typescript@5.3.3
npm install -g vite@5.2.2
