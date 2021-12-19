import logging
import boto3
import time

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

def lambda_handler(event, context):
    tags = [
        { 'Key': 'Name', 'Value': 'Automatic-instance' },
        { 'Key': 'Commit', 'Value': 'abcdh1' },
        { 'Key': 'Time', 'Value': str(int(time.time()))  },
    ]
    response = create(imageId='ami-09e67e426f25ce0d7',
                        keypair='matyas-aws',
                        securityGroup='sg-01bb68fc8f253a182',
                        tags=tags,
                        userScript=DEPLOYMENT_SCRIPT
                        )
    numInstances = len(response['Instances'])
    logger.info('Created {0} instances.'.format(numInstances))
    return {
        "isBase64Encoded": False,
        "statusCode": 200,
        "headers": { "Content-Type": "text/plain" },
        "multiValueHeaders": { },
        "body": 'Created {0} instances.'.format(numInstances)
    }


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