import logging
import boto3
import time
import os
import json
from hmac import HMAC, compare_digest
from hashlib import sha256

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client('lambda')
clientec2 = boto3.client('ec2')

DEPLOYMENT_SCRIPT="""\
#!/bin/bash
git clone https://github.com/jesinmat/LOG8415_simple_aws_app.git app
cd app
./setup.sh &
"""

def verify_source(request):
    if not 'body' in request:
        return False
    if not 'headers' in request:
        return False
    body = request['body']
    headers = request['headers']
    if not 'x-hub-signature-256' in headers:
        return False
    received_sign = headers['x-hub-signature-256'].split('sha256=')[-1].strip()
    secret = os.environ['APP_SECRET_DEPLOY_KEY'].encode()
    logger.info('Received sign: {}'.format(received_sign))
    expected_sign = HMAC(key=secret, msg=body.encode(), digestmod=sha256).hexdigest()
    logger.info('Expected sign: {}'.format(expected_sign))
    return compare_digest(received_sign, expected_sign)

def response(code, text):
    return {
            "isBase64Encoded": False,
            "statusCode": code,
            "headers": { "Content-Type": "text/plain" },
            "multiValueHeaders": { },
            "body": text
        }

def lambda_handler(event, context):
    if not verify_source(event):
        logger.info("Invalid request")
        return response(403, '403 Forbidden')
    body = json.loads(event['body'])
    branch = body['ref'].split("/")[-1]
    if branch != 'main':
        return response(405, 'Deploying not allowed, not on main')
    
    tags = [
        { 'Key': 'Name', 'Value': 'Automatic-instance' },
        { 'Key': 'Commit', 'Value': body['after'][:8] },
        { 'Key': 'Time', 'Value': str(int(time.time()))  },
    ]
    deployResponse = create(imageId='ami-09e67e426f25ce0d7',
                        keypair='matyas-aws',
                        securityGroup='sg-01bb68fc8f253a182',
                        tags=tags,
                        userScript=DEPLOYMENT_SCRIPT
                        )
    numInstances = len(deployResponse['Instances'])
    logger.info('Created {0} instances.'.format(numInstances))
    return response(200, 'Created {0} instances.'.format(numInstances))


def create(
        imageId = "", instanceType = 't2.micro',
        keypair = "", securityGroup = None,
        userScript = '', availabilityZone = 'us-east-1a',
        nbInstances = 1, tags = [], monitoring = False):
    logger.info('Creating instances...')
    return clientec2.run_instances(ImageId=imageId,
                        InstanceType=instanceType,
                        MinCount=nbInstances,
                        MaxCount=nbInstances,
                        KeyName=keypair,
                        SecurityGroupIds=[securityGroup],
                        UserData=userScript,
                        Placement = {
                            'AvailabilityZone': availabilityZone,
                        },
                        TagSpecifications=[{
                            'ResourceType': 'instance',
                            'Tags': tags
                        }],
                        Monitoring={
                            'Enabled': monitoring
                        }
                    )