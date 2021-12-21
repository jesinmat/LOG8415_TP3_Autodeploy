#!/bin/bash
AWS_SECRET_KEY="randomly generated hex string, 32 - 64 characters"
AWS_EC2_KEYPAIR="your AWS keypair name"
APPLICATION_REPO="repository URL of an application for deployment, such as https://github.com/jesinmat/LOG8415_simple_aws_app"

read INSTANCE_TG_ARN < ../tmp/instance-tg-arn.txt
read SECGROUP_ID < ../tmp/sg-id.txt

AWS_ENV="Variables={APP_SECRET_DEPLOY_KEY=$AWS_SECRET_KEY,INSTANCE_TG_ARN=$INSTANCE_TG_ARN,SECGROUP_ID=$SECGROUP_ID,KEYPAIR=$AWS_EC2_KEYPAIR,REPOSITORY_URL=$APPLICATION_REPO}"