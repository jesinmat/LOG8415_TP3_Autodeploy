#!/bin/bash
set -e

read SG_ID < ../tmp/sg-id.txt

echo "Deleting security group..."
aws ec2 delete-security-group --group-id $SG_ID
