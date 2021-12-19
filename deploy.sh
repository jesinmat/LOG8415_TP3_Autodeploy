#!/bin/bash

cd loadbalancer
./deploy.sh

cd ../lambda
./1-create-bucket.sh
./2-deploy.sh

cd ..
echo "Waiting for Load Balancer to be active..."
read LB_ARN < tmp/lb-arn.txt
while true; do
    LB_STATUS=$(aws elbv2 describe-load-balancers --load-balancer-arns "$LB_ARN" --query 'LoadBalancers[0].State.Code')
    if [[ $LB_STATUS == \"active\" ]]; then
        echo "Load Balancer is now active"
        break
    fi
    sleep 10
done

read LB_URL < tmp/lb-url.txt
echo "Access loadbalancer at http://$LB_URL"