#!/bin/bash
echo "--- 🛠️ Installation des outils ---"

# 1. Nettoyage et Installation
sudo rm -f /etc/apt/sources.list.d/yarn.list
sudo apt-get update
sudo apt-get install -y zip jq
pip install awscli awscli-local boto3

# 2. Configuration PERSISTANTE des credentials
echo "--- 🔑 Configuration des identifiants AWS (Fictifs) ---"
aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region us-east-1
aws configure set output json

echo "✅ Environnement prêt et configuré !"