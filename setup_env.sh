#!/bin/bash
echo "--- Installation des outils nécessaires ---"

sudo rm -f /etc/apt/sources.list.d/yarn.list

sudo apt-get update
sudo apt-get install -y zip jq

pip install awscli awscli-local boto3

echo "Environnement prêt !"