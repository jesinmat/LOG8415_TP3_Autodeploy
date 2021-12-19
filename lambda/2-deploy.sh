#!/bin/bash
set -eo pipefail
export AWS_PAGER=""

echo "Deploying lambda functions..."

ARTIFACT_BUCKET=$(cat bucket-name.txt)
aws cloudformation package --template-file template.yml --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml > /dev/null
aws cloudformation deploy --template-file out.yml --stack-name python-deploy-ec2 --capabilities CAPABILITY_NAMED_IAM

source ./secrets.sh

echo "Creating endpoints for lambda functions..."
FUNCTIONS=$(aws lambda list-functions)
DEPLOY_NAME=$(echo $FUNCTIONS | jq -r '.Functions[].FunctionName|select(startswith("python-deploy-ec2-deploy"))')
DEPLOY_ARN=$(echo $FUNCTIONS | jq -r ".Functions[] | select(.FunctionName==\"$DEPLOY_NAME\") | .FunctionArn")
TERMINATE_NAME=$(echo $FUNCTIONS | jq -r '.Functions[].FunctionName|select(startswith("python-deploy-ec2-terminate"))')
TERMINATE_ARN=$(echo $FUNCTIONS | jq -r ".Functions[] | select(.FunctionName==\"$TERMINATE_NAME\") | .FunctionArn")

aws lambda update-function-configuration --function-name "$DEPLOY_NAME" --environment "$AWS_ENV" > /dev/null
aws lambda update-function-configuration --function-name "$TERMINATE_NAME" --environment "$AWS_ENV" > /dev/null

# https://aws.amazon.com/premiumsupport/knowledge-center/elb-register-lambda-as-target-behind-alb/

TG_TERMINATE=$(aws elbv2 create-target-group --name lambda-delete --target-type lambda)
TG_TERMINATE_ARN=$(echo "$TG_TERMINATE" | jq -r '.TargetGroups[0].TargetGroupArn')

aws lambda add-permission \
    --function-name "$TERMINATE_NAME" \
    --statement-id load-balancer \
    --principal elasticloadbalancing.amazonaws.com \
    --action lambda:InvokeFunction \
    --source-arn "$TG_TERMINATE_ARN" > /dev/null

aws elbv2 register-targets \
    --target-group-arn "$TG_TERMINATE_ARN" \
    --targets Id="$TERMINATE_ARN" > /dev/null

read LISTENER_ARN < ../tmp/listener-arn.txt

aws elbv2 create-rule --listener-arn "$LISTENER_ARN" --priority 10 \
    --conditions Field=path-pattern,Values='/lambda/delete' \
    --actions Type=forward,TargetGroupArn="$TG_TERMINATE_ARN" > /dev/null