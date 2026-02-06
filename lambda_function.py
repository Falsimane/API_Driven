import boto3
import json
import os

def lambda_handler(event, context):
    ls_hostname = os.environ.get('LOCALSTACK_HOSTNAME', 'localhost')
    ec2 = boto3.client('ec2', endpoint_url=f"http://{ls_hostname}:4566")
    instance_id = os.environ['INSTANCE_ID']
    path = event.get('resource', '')
    
    msg = ""
    try:
        if '/start' in path:
            ec2.start_instances(InstanceIds=[instance_id])
            msg = "🚀 Démarrage de l'instance initié avec succès."
        elif '/stop' in path:
            ec2.stop_instances(InstanceIds=[instance_id])
            msg = "🛑 Arrêt de l'instance demandé."
        elif '/status' in path:
            msg = "🔍 Vérification de l'état de l'infrastructure..."
        
        desc = ec2.describe_instances(InstanceIds=[instance_id])
        state = desc['Reservations'][0]['Instances'][0]['State']['Name']
        
        return {
            "statusCode": 200, 
            "headers": {"Content-Type": "application/json; charset=utf-8"},
            "body": json.dumps({
                "instance_cible": instance_id, 
                "etat_actuel": state, 
                "message_info": msg
            }, ensure_ascii=False)
        }
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps(str(e))}
