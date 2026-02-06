#!/bin/bash
echo "--- 🛠️ Installation de l'environnement ---"

# Mise à jour et installation de jq (nécessaire pour le 'make test')
sudo apt-get update && sudo apt-get install -y jq zip

# Création dossier virtuel
sudo mkdir -p rep_localstack
# Changement de propriétaire pour éviter les soucis de droits avec pip
sudo chown -R $(whoami) rep_localstack

python3 -m venv ./rep_localstack

# Installation des libs python dans le venv
./rep_localstack/bin/pip install --upgrade pip
./rep_localstack/bin/pip install awscli awscli-local boto3

echo "✅ Environnement prêt dans ./rep_localstack"