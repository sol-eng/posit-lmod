#!/bin/bash

sudo dnf -y install awscli jq git 

sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable --now docker

sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

sudo systemctl enable amazon-ssm-agent

sudo systemctl start amazon-ssm-agent

github_token=`aws secretsmanager get-secret-value --secret-id michael.mayer-github-token --query 'SecretString' --output text | jq -r .token` 

cd /tmp 

git clone https://$github_token@github.com/michaelmayer2/connect-lmod.git

cd connect-lmod
sudo PWD=`pwd` docker compose build  

username=`aws secretsmanager get-secret-value --secret-id michael.mayer-docker-io --query 'SecretString' --output text | jq  -r .username`
password=`aws secretsmanager get-secret-value --secret-id michael.mayer-docker-io --query 'SecretString' --output text | jq  -r .password`

sudo docker login -u $username -p "$password"

sudo docker push mmayer123/posit-lmod

sudo poweroff 
