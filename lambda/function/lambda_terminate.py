import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client('lambda')
clientec2 = boto3.client('ec2')

def lambda_handler(event, context):
    result = deleteOldest()
    logger.info(result)
    return {
        "isBase64Encoded": False,
        "statusCode": 200,
        "headers": { "Content-Type": "text/plain" },
        "multiValueHeaders": { },
        "body": result
    }

def get_instances(response):
    instances = []
    for obj in response['Reservations']:
        instances.extend(obj['Instances'])
    return instances

def deleteOldest():
    name_filter = [{
        'Name':'tag:Name', 
        'Values': ['Automatic-instance']
        },
        {
        'Name': 'instance-state-name',
        'Values': ['running']
        }
    ]
    
    response = clientec2.describe_instances(Filters=name_filter)
    instances = get_instances(response)
    tags = [instance["Tags"] for instance in instances]
    times = []
    for instanceTags in tags:
        time = [kvp['Value'] for kvp in instanceTags if kvp['Key'] == 'Time'][0]
        times.append(int(time))

    if len(times) <= 1:
        return "Cannot terminate more instances - no more instances would be running"

    times.sort()
    lowestTime = str(times[0])
    time_filter = [{
        'Name':'tag:Time', 
        'Values': [lowestTime]}
    ]

    response = clientec2.describe_instances(Filters=time_filter)
    instances = get_instances(response)
    ids = [instance["InstanceId"] for instance in instances]
    clientec2.terminate_instances(InstanceIds=ids)
    return "Terminated {0} oldest instances".format(len(ids))
