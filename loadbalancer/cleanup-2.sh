#!/bin/bash
set -e

read SG_ID < ../tmp/sg-id.txt

echo "Deleting security group..."
sleep 10
aws ec2 delete-security-group --group-id $SG_ID
