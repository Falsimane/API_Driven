------------------------------------------------------------------------------------------------------
LANCEMENT ATELIER API-DRIVEN
------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------
Prérequis
------------------------------------------------------------------------------------------------------
- Un Codespace GitHub ouvert sur ce dépôt.
- Accès au port 4566 en public dans l'onglet [PORTS] (le port se lancera avec le make all).

------------------------------------------------------------------------------------------------------
Démarrage rapide
------------------------------------------------------------------------------------------------------
Dans un terminal :

```bash
make all
```

------------------------------------------------------------------------------------------------------
Utilisation
------------------------------------------------------------------------------------------------------
Trois routes sont exposées :

- /status : retourne l'état de l'instance.
- /start : démarre l'instance.
- /stop : arrête l'instance.

Exemples :

```bash
curl "<URL_BASE>/status"
curl "<URL_BASE>/start"
curl "<URL_BASE>/stop"
```

La reponse est au format JSON et contient :
- instance_cible
- etat_actuel
- message_info

------------------------------------------------------------------------------------------------------
Details techniques
------------------------------------------------------------------------------------------------------
Le script [setup_env.sh](setup_env.sh) effectue :
- création d'une instance EC2 locale via LocalStack
- création d'un rôle IAM minimal
- création de la fonction Lambda
- création des routes API Gateway

La fonction Lambda est dans [lambda_function.py](lambda_function.py). Elle choisit l'action selon
la route appelée et renvoie l'état de l'instance.

------------------------------------------------------------------------------------------------------
Arrêt et nettoyage
------------------------------------------------------------------------------------------------------
```bash
make stop
make clean
```
