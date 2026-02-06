# Makefile pour API-Driven Infrastructure
# Automatisation des Séquences 1, 2 et 3

# --- CONFIGURATION UTF-8 & SHELL ---
SHELL := /bin/bash
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Variables
VENV_DIR = rep_localstack
ACTIVATE = . $(VENV_DIR)/bin/activate

# Couleurs pour le terminal
YELLOW = \033[1;33m
CYAN = \033[0;36m
GREEN = \033[0;32m
BLUE = \033[0;34m
RED = \033[0;31m
GRAY = \033[0;90m
BOLD = \033[1m
RESET = \033[0m

# Style d'affichage
LINE = $(GRAY)────────────────────────────────────────────────────────$(RESET)
TAG_INFO = $(BLUE)ℹ️  INFO$(RESET)
TAG_OK = $(GREEN)✅ OK$(RESET)
TAG_WARN = $(YELLOW)⚠️  WARN$(RESET)
TAG_STEP = $(CYAN)➜ STEP$(RESET)

.PHONY: install start deploy stop clean all

# --- CIBLES ---

install:
	@echo -e "$(LINE)"
	@echo -e "$(BOLD)📦 Séquence 2 · Installation$(RESET)"
	@echo -e "$(LINE)"
	@echo -e "$(TAG_STEP) Création de l'environnement virtuel"
	python3 -m venv $(VENV_DIR)
	@echo -e "$(TAG_STEP) Installation des dépendances (LocalStack & AWS CLI)"
	$(ACTIVATE) && pip install --upgrade pip > /dev/null
	$(ACTIVATE) && pip install localstack awscli-local awscli > /dev/null
	@echo -e "$(TAG_OK) Installation terminée"

start:
	@echo -e "$(LINE)"
	@echo -e "$(BOLD)🚀 Séquence 2 · Démarrage LocalStack$(RESET)"
	@echo -e "$(LINE)"
	$(ACTIVATE) && export S3_SKIP_SIGNATURE_VALIDATION=0 && localstack start -d
	@echo -e "$(TAG_INFO) Attente de la disponibilité des services AWS..."
	@sleep 10
	$(ACTIVATE) && localstack status services
	@echo ""
	@echo -e "$(YELLOW)════════════════════════════════════════════════════════════$(RESET)"
	@echo -e "$(TAG_WARN) ACTION REQUISE : RÉCUPÉRATION DE L'API AWS LOCALSTACK"
	@echo -e "$(YELLOW)════════════════════════════════════════════════════════════$(RESET)"
	@echo "Votre environnement AWS (LocalStack) est prêt."
	@echo -e "1) Cliquez sur l'onglet $(CYAN)[PORTS]$(RESET) dans votre Codespace."
	@echo -e "2) Rendez $(CYAN)public$(RESET) votre port $(CYAN)4566$(RESET) (Visibilité du port)."
	@echo -e "3) L'URL sera automatiquement détectée par le script !"
	@echo ""
	@echo -e "💡 $(CYAN)Note :$(RESET) Rien n'apparaît dans le navigateur, c'est normal."
	@echo "   Il s'agit d'une API AWS (pas une UX Web)."
	@echo -e "$(YELLOW)════════════════════════════════════════════════════════════$(RESET)"

deploy:
	@echo -e "$(LINE)"
	@echo -e "$(BOLD)🧱 Séquence 3 · Déploiement$(RESET)"
	@echo -e "$(LINE)"
	@echo -e "$(TAG_INFO) Préparation du script"
	chmod +x setup_env.sh
	@echo -e "$(TAG_STEP) Lancement de l'orchestration"
	$(ACTIVATE) && ./setup_env.sh
	@echo -e "$(TAG_OK) Déploiement terminé"

stop:
	@echo -e "$(LINE)"
	@echo -e "$(BOLD)🛑 Arrêt des services$(RESET)"
	@echo -e "$(LINE)"
	$(ACTIVATE) && localstack stop
	@echo -e "$(TAG_OK) Services arrêtés"

clean:
	@echo -e "$(LINE)"
	@echo -e "$(BOLD)🧹 Nettoyage de l'environnement$(RESET)"
	@echo -e "$(LINE)"
	@echo -e "$(TAG_INFO) Suppression de $(VENV_DIR) et des artefacts"
	rm -rf $(VENV_DIR)
	rm -f function.zip lambda_function.py
	@echo -e "$(TAG_OK) Nettoyage effectué"

all: install start deploy 