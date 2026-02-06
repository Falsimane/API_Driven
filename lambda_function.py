import boto3
import json
import os

def lambda_handler(event, context):
    ls_host = os.environ.get('LOCALSTACK_HOSTNAME', 'localhost')
    ec2 = boto3.client('ec2', endpoint_url=f"http://{ls_host}:4566")
    target = os.environ['INSTANCE_ID']
    path = event.get('resource', '')
    
    msg = "Statut consulté."
    try:
        if '/start' in path:
            ec2.start_instances(InstanceIds=[target])
            msg = "🚀 Démarrage demandé."
        elif '/stop' in path:
            ec2.stop_instances(InstanceIds=[target])
            msg = "🛑 Arrêt demandé."
        
        state = ec2.describe_instances(InstanceIds=[target])['Reservations'][0]['Instances'][0]['State']['Name']
        
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"id": target, "state": state, "info": msg})
        }
    except Exception as e:
        return {"statusCode": 500, "body": str(e)}
