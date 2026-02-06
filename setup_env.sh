#!/bin/bash
echo "--- Installation des outils nécessaires ---"

# Installation des packages 
pip install awscli-local boto3
sudo apt-get update && sudo apt-get install -y zip jq

echo "Environnement prêt !" 
