#!/bin/bash
set -e

read LB_ARN < ../tmp/lb-arn.txt
read LB_URL < ../tmp/lb-url.txt
read TG_ARN < ../tmp/instance-tg-arn.txt

echo "Deleting loadbalancer..."
aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN
sleep 20

echo "Deleting target group for EC2 instances..."
aws elbv2 delete-target-group --target-group-arn $TG_ARN

echo "Completed loadbalancer cleanup."