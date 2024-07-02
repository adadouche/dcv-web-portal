#!/bin/bash

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo add-apt-repository ppa:deadsnakes/ppa -y

sudo apt-get update -y -q

sudo apt-get install -y -q jq
sudo apt-get install -y -q node-typescript
sudo apt-get install -y -q eslint
sudo apt-get install -y -q curl

sudo apt-get install -y -q awscli 
sudo apt-get install -y -q gnupg software-properties-common
sudo apt-get install -y -q terraform
sudo apt-get install -y -q unzip 

sudo apt-get install python3.11 -y -q
sudo apt-get install python3-pip -y -q

sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 2
sudo update-alternatives --config python3aws configure

npm cache clean -f
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash # need to reopen the terminal after

nvm install 20

current_version=$(node -v)
current_version="${current_version:1}"

nvm alias default node $current_version

npm install -g npm@10.3.0
npm install -g typescript@5.3.3
npm install -g vite@5.2.2

sudo apt-get install nginx