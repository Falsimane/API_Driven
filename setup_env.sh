#!/bin/bash

# --- CONFIGURATION ---
export LANG=C.UTF-8
AWS_CMD="awslocal"
LAMBDA_NAME="ManageEC2"
API_NAME="EC2Controller"

# Couleurs
MSG='\033[0;34m' # Bleu
OK='\033[0;32m'  # Vert
WARN='\033[1;33m' # Jaune
NC='\033[0m'     # No Color

log() { echo -e "${MSG}[SCRIPT] $1${NC}"; }
success() { echo -e "${OK} ✔️ $1${NC}"; }

# --- DETECTION URL ---
detect_url() {
    if [ -z "$CODESPACE_NAME" ]; then
        BASE_URL="http://localhost:4566"
    else
        BASE_URL="https://${CODESPACE_NAME}-4566.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
    fi
}

# --- 1. PROVISIONING EC2 ---
provision_ec2() {
    log "Création instance EC2..."
    TARGET_VM_ID=$($AWS_CMD ec2 run-instances \
        --image-id ami-linux-2026 \
        --count 1 \
        --instance-type t2.micro \
        --query 'Instances[0].InstanceId' \
        --output text)
    success "Instance: $TARGET_VM_ID"
}

# --- 2. IAM ---
setup_iam() {
    log "Configuration IAM..."
    ROLE_NAME="lambda-gateway-role"
    
    # Clean up préventif
    $AWS_CMD iam delete-role-policy --role-name $ROLE_NAME --policy-name lambda-policy >/dev/null 2>&1
    $AWS_CMD iam delete-role --role-name $ROLE_NAME >/dev/null 2>&1
    
    TRUST_POLICY='{"Version": "2012-10-17","Statement": [{"Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
    $AWS_CMD iam create-role --role-name $ROLE_NAME --assume-role-policy-document "$TRUST_POLICY" > /dev/null
    success "Rôle IAM prêt."
}

# --- 3. LAMBDA CODE ---
generate_lambda() {
    log "Génération du code Python..."
    cat <<EOF > lambda_function.py
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
EOF
    rm -f function.zip && zip -q function.zip lambda_function.py
    success "Lambda zippée."
}

# --- 4. DEPLOIEMENT ---
deploy_stack() {
    log "Déploiement Lambda & API Gateway..."
    $AWS_CMD lambda delete-function --function-name $LAMBDA_NAME >/dev/null 2>&1
    
    LAMBDA_ARN=$($AWS_CMD lambda create-function \
        --function-name $LAMBDA_NAME \
        --zip-file fileb://function.zip \
        --handler lambda_function.lambda_handler \
        --runtime python3.9 \
        --role arn:aws:iam::000000000000:role/lambda-gateway-role \
        --environment Variables="{INSTANCE_ID=$TARGET_VM_ID}" \
        --query 'FunctionArn' --output text)

    API_ID=$($AWS_CMD apigateway create-rest-api --name "$API_NAME" --query 'id' --output text)
    ROOT_ID=$($AWS_CMD apigateway get-resources --rest-api-id $API_ID --query 'items[0].id' --output text)

    create_route() {
        R_ID=$($AWS_CMD apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_ID --path-part $1 --query 'id' --output text)
        $AWS_CMD apigateway put-method --rest-api-id $API_ID --resource-id $R_ID --http-method GET --authorization-type NONE >/dev/null
        $AWS_CMD apigateway put-integration --rest-api-id $API_ID --resource-id $R_ID --http-method GET \
            --type AWS_PROXY --integration-http-method POST \
            --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations >/dev/null
    }

    create_route "start"
    create_route "stop"
    create_route "status"
    $AWS_CMD apigateway create-deployment --rest-api-id $API_ID --stage-name prod >/dev/null
    
    FINAL_URL="${BASE_URL}/restapis/${API_ID}/prod/_user_request_"
    success "API déployée avec succès."
    
    echo ""
    echo -e "${WARN}👇 TESTEZ VOTRE INFRASTRUCTURE ICI :${NC}"
    echo -e "1. ${FINAL_URL}/status"
    echo -e "2. ${FINAL_URL}/start"
    echo -e "3. ${FINAL_URL}/stop"
    echo ""
}

# --- MAIN ---
clear
detect_url
pip install awscli-local awscli > /dev/null 2>&1
provision_ec2
setup_iam
generate_lambda
deploy_stack