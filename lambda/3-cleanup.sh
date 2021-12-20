#!/bin/bash
set -eo pipefail
STACK=tp3
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deleting stack $STACK"
fi
DEPLOY=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id 'deploy' --query 'StackResourceDetail.PhysicalResourceId' --output text)
TERMINATE=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id 'terminate' --query 'StackResourceDetail.PhysicalResourceId' --output text)
TG_LAMBDA=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id 'targetgroup' --query 'StackResourceDetail.PhysicalResourceId' --output text)
aws cloudformation delete-stack --stack-name $STACK
echo "Deleted $STACK stack."

if [ -f bucket-name.txt ]; then
    ARTIFACT_BUCKET=$(cat bucket-name.txt)
    if [[ ! $ARTIFACT_BUCKET =~ lambda-source-code-[a-z0-9]{16} ]] ; then
        echo "Bucket was not created by this application. Skipping."
    else
        echo "Deleting S3 bucket..."
        aws s3 rb --force s3://$ARTIFACT_BUCKET
        rm bucket-name.txt
    fi
fi

echo "Deleting logs..."
aws logs delete-log-group --log-group-name /aws/lambda/$DEPLOY > /dev/null 2>&1 || true
aws logs delete-log-group --log-group-name /aws/lambda/$TERMINATE > /dev/null 2>&1 || true
aws logs delete-log-group --log-group-name /aws/lambda/$TG_LAMBDA > /dev/null 2>&1 || true

echo "Deleting running instances..."
INST=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=Automatic-instance" --query 'Reservations[*].Instances[*].InstanceId')
IDS=$(echo "$INST" | jq -r '.[][]' | tr '\n' ' ')
IDS_LEN=${#IDS}
if [ "$IDS_LEN" -gt 2 ]; then
    TERMINATE_CMD=$(echo aws ec2 terminate-instances --instance-ids "$IDS")
    RESULT=$(eval "$TERMINATE_CMD")
fi

echo "Deleting lambda target groups..."
read TG_TERMINATE_ARN < ../tmp/lambda-terminate-tg-arn.txt
aws elbv2 delete-target-group --target-group-arn $TG_TERMINATE_ARN

read TG_DEPLOY_ARN < ../tmp/lambda-deploy-tg-arn.txt
aws elbv2 delete-target-group --target-group-arn $TG_DEPLOY_ARN

rm -f out.yml
rm -rf package function/__pycache__

echo "Completed lambda cleanup."
