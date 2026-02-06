import boto3
import json 
import os 

# On retire l'URL par défaut pour forcer l'usage du Makefile (Clean Code)
ENDPOINT_URL = os.environ.get("ENDPOINT_URL")

def lambda_handler(event, context): 
    # Sécurité si l'URL manque
    if not ENDPOINT_URL:
        return {"statusCode": 500, "body": json.dumps("Erreur config: ENDPOINT_URL manquant")}

    print(f"Connexion à l'endpoint : {ENDPOINT_URL}")

    ec2 = boto3.client("ec2", endpoint_url=ENDPOINT_URL, region_name="us-east-1")

    # CORRECTION IMPORTANTE ICI : Le 'or {}' doit être dehors !
    params = event.get("queryStringParameters") or {}
    
    action = params.get("action")
    instance_id = params.get("instance_id")

    if not action or not instance_id:
        return {
            "statusCode": 400,
            "body": json.dumps("Erreur: Paramètres 'action' et 'instance_id' requis.")
        }

    try:
        if action == "start":
            ec2.start_instances(InstanceIds=[instance_id])
            msg = f"Instance {instance_id} démarrée."
        elif action == "stop":
            ec2.stop_instances(InstanceIds=[instance_id])
            msg = f"Instance {instance_id} arrêtée."
        else:
            return {
                "statusCode": 400,
                "body": json.dumps("Action invalide (start/stop uniquement).")
            }
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": msg,
                "endpoint": ENDPOINT_URL
            })
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps(f"Erreur AWS: {str(e)}")
        }