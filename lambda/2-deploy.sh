#!/bin/bash
set -eo pipefail
ARTIFACT_BUCKET=$(cat bucket-name.txt)
aws cloudformation package --template-file template.yml --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml
aws cloudformation deploy --template-file out.yml --stack-name python-deploy-ec2 --capabilities CAPABILITY_NAMED_IAM

source ./secrets.sh

FUNCTIONS=$(aws lambda list-functions --query 'Functions[*].FunctionName')
DEPLOY=$(echo "$FUNCTIONS" | jq -r '.[]|select(startswith("python-deploy-ec2-deploy"))')
TERMINATE=$(echo "$FUNCTIONS" | jq -r '.[]|select(startswith("python-deploy-ec2-deploy"))')

aws lambda update-function-configuration --function-name "$DEPLOY" --environment "$AWS_ENV"
aws lambda update-function-configuration --function-name "$TERMINATE" --environment "$AWS_ENV"