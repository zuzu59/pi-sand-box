# pi-sand-box

Environnement sandbox pour utiliser **Pi Coding Agent** dans un conteneur Docker. Pi et les commandes lancées par l’agent s’exécutent dans le conteneur, tandis que les fichiers de travail sont conservés sur l’hôte dans `project_code/`.

## Prérequis

- Docker Engine et le plugin Docker Compose (`docker compose`)
- Une connexion Internet pour construire l’image et installer Pi

## Installation

Depuis la racine du projet, construisez l’image et démarrez le conteneur :

```bash
docker compose up -d --build
```

Vérifiez qu’il fonctionne :

```bash
docker compose ps
```

Le service démarre un conteneur persistant nommé `pi_coding_sandbox`. Il est limité à 2 processeurs et 2 Go de mémoire. Le dossier `project_code/` est monté dans `/workspace` et le dossier local `pi_home/` dans `/root/.pi`.

## Utilisation

Ouvrez une session Pi interactive avec `docker exec` :

```bash
docker exec -it pi_coding_sandbox pi
```

Pi démarre dans `/workspace`. Les projets créés ou modifiés à cet endroit sont accessibles directement depuis l’hôte dans `project_code/`.

Pour lancer une commande ponctuelle dans le conteneur :

```bash
docker exec -it pi_coding_sandbox bash
```

Puis, dans le shell, lancez par exemple `pi` ou les commandes de votre projet. Vous pouvez aussi exécuter une commande directement, sans ouvrir de shell :

```bash
docker exec pi_coding_sandbox pwd
```

Au premier lancement de Pi, suivez les instructions pour configurer l’authentification du fournisseur de modèle souhaité. La configuration et les sessions sont conservées dans `pi_home/` entre les redémarrages. Ce dossier est destiné aux données locales et n’est pas versionné par Git.

## Arrêt et maintenance

Arrêter le conteneur sans supprimer les données :

```bash
docker compose down
```

Le redémarrer :

```bash
docker compose up -d
```

Reconstruire l’image après une modification du `dockerfile` :

```bash
docker compose up -d --build
```

## Fichiers du projet

- `dockerfile` : image basée sur Node.js 24, avec les outils système nécessaires et Pi Coding Agent installé globalement.
- `docker-compose.yml` : définition du service, des ressources et des volumes persistants.
- `project_code/` : espace de travail partagé avec le conteneur (`/workspace`).
- `pi_home/` : configuration, authentification et sessions Pi locales (`/root/.pi`), exclues du dépôt.
