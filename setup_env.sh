#!/bin/bash
echo "--- Installation des outils nécessaires ---"

# Installation des packages 
pip install awscli-local boto3
sudo apt-get update && sudo apt-get install -y zip jq

# Configuration des identifiants de test pour LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

echo "Environnement prêt !" 
