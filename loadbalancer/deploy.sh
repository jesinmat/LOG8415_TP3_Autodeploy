#!/bin/bash

# Create security group
echo "Creating security group..."
SEC_GROUP=$(aws ec2 create-security-group --group-name "HTTP" --description "HTTP only")
SG_ID=$(echo $SEC_GROUP | jq -r '.GroupId')
ADD_PORT=$(aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0)

echo "Creating load balancer..."
SUBNETS=$(aws ec2 describe-subnets --query 'Subnets[*].SubnetId' | jq -r '.[]' | tr '\n' ' ')
LB_CMD=$(echo aws elbv2 create-load-balancer --name my-load-balancer --subnets $SUBNETS --security-groups "$SG_ID")
LOADBALANCER=$(eval "$LB_CMD")
VPC_ID=$(echo $LOADBALANCER | jq -r '.LoadBalancers[0].VpcId')
LB_ARN=$(echo $LOADBALANCER | jq -r '.LoadBalancers[0].LoadBalancerArn')

echo "Creating target groups for instances..."
TGROUP=$(aws elbv2 create-target-group --name "automated-instances" --protocol HTTP --port 80 --vpc-id "$VPC_ID")
TG_ARN=$(echo "$TGROUP" | jq -r '.TargetGroups[0].TargetGroupArn')

echo "Creating listener..."
LISTENER=$(aws elbv2 create-listener --load-balancer-arn "$LB_ARN" --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn="$TG_ARN")
LISTENER_ARN=$(echo "$LISTENER" | jq -r '.Listeners[0].ListenerArn')

# Register targets - add instances from code https://docs.aws.amazon.com/elasticloadbalancing/latest/application/tutorial-application-load-balancer-cli.html

mkdir -p ../tmp
echo "$LB_ARN" > ../tmp/lb-arn.txt
echo "$TG_ARN" > ../tmp/instance-tg-arn.txt
echo "$LISTENER_ARN" > ../tmp/listener-arn.txt

echo "LoadBalancer is ready"
