import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client('lambda')
clientec2 = boto3.client('ec2')

def lambda_handler(event, context):
    tags = [
        { 'Key': 'Name', 'Value': 'Hello-world2' },
    ]
    response = create(imageId='ami-09e67e426f25ce0d7', keypair='matyas-aws', securityGroup='sg-01bb68fc8f253a182', tags=tags)
    logger.info('Created {0} instances.'.format(len(response['Instances'])))
    return "Started {0} instances.".format(len(response['Instances']))


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