#!/bin/bash

# --- CONFIGURATION UTF-8 ---
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# --- COULEURS ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

# --- STYLE ---
LINE="${GRAY}────────────────────────────────────────────────────────${NC}"
TAG_INFO="${BLUE}ℹ️  INFO${NC}"
TAG_OK="${GREEN}✅ OK${NC}"
TAG_STEP="${CYAN}➜ STEP${NC}"

clear
echo -e "${LINE}"
echo -e "${BOLD}🧭 Initialisation de l'environnement API-Driven${NC}"
echo -e "${LINE}"
echo ""

# --- URL AUTO-DETECT ---
if [ -z "$CODESPACE_NAME" ]; then
    API_URL="http://localhost:4566"
    echo -e "${TAG_INFO} Environnement local détecté"
else
    API_URL="https://${CODESPACE_NAME}-4566.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
    echo -e "${TAG_INFO} Environnement Codespace détecté"
fi
echo -e "${TAG_INFO} URL cible : ${API_URL}"
echo ""

# Installation silencieuse
echo -ne "${TAG_STEP} [1/5] Vérification des outils AWS..."
# --- CORRECTION ICI : Installation de awscli ET awscli-local ---
pip install awscli-local awscli > /dev/null 2>&1
echo -e " ${TAG_OK}"

# 1. Creation EC2
echo -ne "${TAG_STEP} [2/5] Lancement de l'instance EC2..."
INSTANCE_ID=$(awslocal ec2 run-instances --image-id ami-ff000000 --count 1 --instance-type t2.micro --query 'Instances[0].InstanceId' --output text)
echo -e " ${TAG_OK} (${INSTANCE_ID})"

# 2. Role IAM
echo -ne "${TAG_STEP} [3/5] Sécurisation IAM..."
awslocal iam delete-role-policy --role-name lambda-ec2-role --policy-name lambda-policy > /dev/null 2>&1 || true
awslocal iam delete-role --role-name lambda-ec2-role > /dev/null 2>&1 || true
awslocal iam create-role --role-name lambda-ec2-role --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}' > /dev/null
echo -e " ${TAG_OK}"

# 3. Code Lambda
echo -ne "${TAG_STEP} [4/5] Génération du code Lambda..."
cat <<EOF > lambda_function.py
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
EOF
rm -f function.zip
zip function.zip lambda_function.py > /dev/null
echo -e " ${TAG_OK}"

# 4. Deploiement Lambda & API
echo -ne "${TAG_STEP} [5/5] Déploiement API Gateway..."
awslocal lambda delete-function --function-name ManageEC2 > /dev/null 2>&1 || true

LAMBDA_ARN=$(awslocal lambda create-function \
    --function-name ManageEC2 \
    --zip-file fileb://function.zip \
    --handler lambda_function.lambda_handler \
    --runtime python3.9 \
    --role arn:aws:iam::000000000000:role/lambda-ec2-role \
    --environment Variables="{INSTANCE_ID=$INSTANCE_ID}" \
    --query 'FunctionArn' --output text)

API_ID=$(awslocal apigateway create-rest-api --name "EC2Controller" --query 'id' --output text)
PARENT_ID=$(awslocal apigateway get-resources --rest-api-id $API_ID --query 'items[0].id' --output text)

create_route() {
    PATH_PART=$1
    RES_ID=$(awslocal apigateway create-resource --rest-api-id $API_ID --parent-id $PARENT_ID --path-part $PATH_PART --query 'id' --output text)
    awslocal apigateway put-method --rest-api-id $API_ID --resource-id $RES_ID --http-method GET --authorization-type NONE > /dev/null
    awslocal apigateway put-integration --rest-api-id $API_ID --resource-id $RES_ID --http-method GET --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations > /dev/null
}

create_route "start"
create_route "stop"
create_route "status"

awslocal apigateway create-deployment --rest-api-id $API_ID --stage-name prod > /dev/null
echo -e " ${TAG_OK}"

# --- RESULTATS ---
FINAL_URL="${API_URL}/restapis/${API_ID}/prod/_user_request_"

echo ""
echo -e "${LINE}"
echo -e "${BOLD}🎉 Installation terminee${NC}"
echo -e "${LINE}"
echo ""
echo -e "${TAG_INFO} Endpoints disponibles :"
echo -e "  - STATUT : ${FINAL_URL}/status"
echo -e "  - START  : ${FINAL_URL}/start"
echo -e "  - STOP   : ${FINAL_URL}/stop"
echo ""