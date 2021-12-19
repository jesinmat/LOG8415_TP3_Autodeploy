import logging
import boto3
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

elbv2 = boto3.client('elbv2')

def lambda_handler(event, context):
    logger.info(event)
    instanceId = event['Records'][0]['body']
    res = elbv2.register_targets(
            TargetGroupArn=os.environ['INSTANCE_TG_ARN'],
            Targets=[
                {
                    'Id': instanceId
                },
            ])
    return 'Success'
