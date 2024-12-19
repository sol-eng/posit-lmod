#!/bin/bash

VPC_ID="vpc-1486376d"
POSIT_TAGS="{Key=rs:project,Value=solutions}, \
            {Key=rs:environment,Value=development}, \
            {Key=rs:owner,Value=michael.mayer@posit.co}"

AMI_ID="ami-05a40a9d755b0f73a" 

SUBNET_ID="subnet-9bbd91c1" 

SG_ID=`aws ec2 create-security-group \
    --group-name ssh-posit-lmod-sg \
    --description "SG for Posit Lmod SSH (port 22) access" \
    --tag-specifications "ResourceType=security-group,\
        Tags=[{Key=Name,Value=ssh-wb-sg},${POSIT_TAGS}]" \
    --vpc-id "${VPC_ID}" | jq -r '.GroupId' `

if [ "$SG_ID" == "" ]; then 
    SG_ID=`aws ec2 describe-security-groups --filters Name=group-name,Values=ssh-posit-lmod-sg --query 'SecurityGroups[0].GroupId' --output text`
fi

aws ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" \
    --protocol tcp \
    --port 22 \
    --cidr "84.73.132.160/32"

aws iam create-policy --policy-name mmayer-docker.io --policy-document file://getsecret.json

aws iam create-role --role-name mmayer-EC2GetSecretRole --assume-role-policy-document file://trust.json

aws iam attach-role-policy --role-name mmayer-EC2GetSecretRole --policy-arn arn:aws:iam::637485797898:policy/mmayer-docker.io

aws iam attach-role-policy --role-name mmayer-EC2GetSecretRole --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

aws iam create-instance-profile --instance-profile-name mmayer-EC2InstanceProfile
aws iam add-role-to-instance-profile --instance-profile-name mmayer-EC2InstanceProfile --role-name mmayer-EC2GetSecretRole 

aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-initiated-shutdown-behavior terminate \
    --instance-type t3.2xlarge \
    --security-group-ids $SG_ID \
    --iam-instance-profile Name=mmayer-EC2InstanceProfile \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":100,\"DeleteOnTermination\":true}}]" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=rl9-posit-lmod},${POSIT_TAGS}]" 'ResourceType=volume,Tags=[{Key=Name,Value=rl9-posit-lmod-disk}]' \
    --user-data file://${PWD}/user-data.sh
