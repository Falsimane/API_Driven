# Makefile pour API-Driven Infrastructure (Mode Interactif & Clean)
# Version: 2.2 | Auto-Stop on Clean

# --- VARIABLES ---
SHELL := /bin/bash
PROJECT_NAME = infra-localstack
VENV = .venv_aws
BIN = $(VENV)/bin
ACTIVATE = source $(BIN)/activate

# --- ESTHÉTIQUE ---
BOLD = \033[1m
GREEN = \033[32m
CYAN = \033[36m
AMBER = \033[33m
RED = \033[31m
RESET = \033[0m

.PHONY: all install start pause deploy stop clean

all: install start pause deploy

install:
	@echo -e "$(CYAN)📦 [1/4] Installation de l'environnement...$(RESET)"
	@test -d $(VENV) || python3 -m venv $(VENV)
	@$(ACTIVATE) && pip install --quiet --upgrade pip && \
		pip install --quiet localstack awscli-local awscli
	@echo -e "$(GREEN)✅ Dépendances installées.$(RESET)"

start:
	@echo -e "$(CYAN)⚡ [2/4] Démarrage de LocalStack...$(RESET)"
	@$(ACTIVATE) && export S3_SKIP_SIGNATURE_VALIDATION=0 && localstack start -d
	@echo -e "   ⏳ Attente de disponibilité des services (Health Check)..."
	@sleep 10
	@$(ACTIVATE) && localstack wait -t 30 > /dev/null && \
		echo -e "$(GREEN)✅ LocalStack est en ligne.$(RESET)"

pause:
	@echo ""
	@echo -e "$(RED)============================================================$(RESET)"
	@echo -e "$(BOLD)🛑 STOP ! ACTION REQUISE MAINTENANT 🛑$(RESET)"
	@echo -e "$(RED)============================================================$(RESET)"
	@echo -e "1. Allez dans l'onglet $(BOLD)'PORTS'$(RESET) du Codespace."
	@echo -e "2. Cherchez le port $(BOLD)4566$(RESET)."
	@echo -e "3. Changez la visibilité de 'Private' à $(GREEN)$(BOLD)'Public'$(RESET)."
	@echo ""
	@echo -ne "$(AMBER)👉 Une fois que c'est fait, appuyez sur [ENTRÉE] pour continuer...$(RESET)"
	@read -p "" dummy
	@echo -e "$(GREEN)✅ Reprise du déploiement...$(RESET)"

deploy:
	@echo -e "$(CYAN)🏗️  [3/4] Déploiement de l'infrastructure...$(RESET)"
	@chmod +x setup_env.sh
	@$(ACTIVATE) && ./setup_env.sh

stop:
	@echo -e "$(AMBER)🛑 Arrêt des services...$(RESET)"
	@# Le '|| true' permet de ne pas planter si le venv n'existe plus
	@test -f $(BIN)/activate && ($(ACTIVATE) && localstack stop) || echo "   (LocalStack déjà arrêté ou venv introuvable)"
	@echo -e "$(GREEN)✅ Services arrêtés.$(RESET)"

# ICI : On appelle 'stop' avant de faire le ménage
clean: stop
	@echo -e "$(AMBER)🧹 Suppression des fichiers...$(RESET)"
	rm -rf $(VENV) function.zip
	@echo -e "$(GREEN)✨ Environnement entièrement nettoyé.$(RESET)"