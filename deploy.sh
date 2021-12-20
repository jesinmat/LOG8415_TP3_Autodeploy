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

echo "Calling lambda to deploy initial instances..."
python3 call-deploy-lambda.py
echo "Instances queued for deployment. They will be ready in approximately 60 seconds."

read LB_URL < tmp/lb-url.txt
echo "##########################################"
echo ""
echo "Access application at http://$LB_URL"
echo "Create a GitHub webhook with the following url: http://${LB_URL}/lambda/deploy and publish a change to the repository" 
echo "To delete oldest running instances, visit: http://${LB_URL}/lambda/delete" 