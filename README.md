# pi-sand-box

Environnement sandbox pour utiliser **Pi Coding Agent** dans un conteneur Docker. Pi et les commandes lancées par l’agent s’exécutent dans le conteneur, tandis que les fichiers de travail sont conservés sur l’hôte dans `project_code/`.

## Prérequis

- Un système Linux basé sur Debian/Ubuntu avec `sudo` et une connexion Internet
- Docker Engine et le plugin Docker Compose (`docker compose`)

Si Docker n’est pas encore installé, le dépôt fournit le script `install_docker.sh`. Depuis la racine du projet, exécutez-le avec les droits nécessaires :

```bash
sudo LOGNAME="$USER" bash ./install_docker.sh
```

Le script installe Docker et ajoute l’utilisateur courant au groupe `docker`. Déconnectez-vous puis reconnectez-vous pour que le changement de groupe soit pris en compte, puis vérifiez l’installation :

```bash
docker --version
docker compose version
```

## Installation

Depuis la racine du projet, construisez l’image et démarrez le conteneur :

```bash
docker compose up -d --build
```

Vérifiez qu’il fonctionne :

```bash
docker compose ps
```

Le service démarre un conteneur persistant nommé `pi_coding_sandbox`, avec le nom d’hôte `dev-container` (affiché dans le prompt SSH). Il est limité à 2 processeurs et 2 Go de mémoire. Le dossier `project_code/` est monté dans `/workspace` et `root_home/` dans `/root` : le dossier personnel complet de l’utilisateur `root` est ainsi conservé sur l’hôte, y compris Pi dans `/root/.pi`, ainsi que les autres configurations et fichiers personnels.

## Accès au conteneur en SSH

Le conteneur démarre OpenSSH sur le port `2222`, publié sur `0.0.0.0` (toutes les interfaces IPv4 de l’hôte). Les ports de développement `8080`, `8081`, `8090`, `8091`, `3000` et `3001` sont également publiés sur toutes les interfaces, chacun vers le même port du conteneur. L’accès au compte `root` est possible par mot de passe ou par clé SSH. Le mot de passe est fourni via le fichier local `.env` (ignoré par Git) :

Un modèle est fourni dans `.env.sample`. Copiez-le dans `.env` et remplacez la valeur d’exemple :

```bash
cp .env.sample .env
```

Vous pouvez aussi générer un mot de passe aléatoire directement dans `.env` :

```bash
printf 'ROOT_PASSWORD=%s\n' "$(openssl rand -hex 24)" > .env
```

Ne partagez pas le fichier `.env` et ne conservez pas la valeur fictive du modèle.

Pour l’authentification par clé (facultative), ajoutez votre clé publique à `root_home/.ssh/authorized_keys` (créez le dossier si nécessaire) :

```bash
mkdir -p root_home/.ssh
cat ~/.ssh/id_ed25519.pub >> root_home/.ssh/authorized_keys
chmod 700 root_home/.ssh
chmod 600 root_home/.ssh/authorized_keys
```

Démarrez ou reconstruisez le conteneur, puis connectez-vous depuis la machine hôte :

```bash
docker compose up -d --build
ssh -p 2222 root@ADRESSE_IP_DE_L_HOTE
```

SSH demandera le mot de passe défini dans `.env` (ou utilisera votre clé si elle est autorisée).

Le bind sur `0.0.0.0` rend ces ports accessibles depuis les interfaces réseau de l’hôte. Protégez l’accès avec un mot de passe fort, privilégiez les clés SSH et configurez le pare-feu pour limiter les connexions aux réseaux de confiance. Les applications de développement doivent écouter sur `0.0.0.0` à l’intérieur du conteneur pour être accessibles via les ports publiés.

## Utilisation

Vous pouvez toujours ouvrir une session Pi interactive avec `docker exec` :

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

Au premier lancement de Pi, suivez les instructions pour configurer l’authentification du fournisseur de modèle souhaité. La configuration et les sessions sont conservées dans `root_home/.pi/` entre les redémarrages. Tout le contenu de `root_home/` est local et n’est pas versionné par Git. L’ancienne configuration présente dans `pi_home/` a été copiée vers `root_home/.pi/`.

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

- `ARCHITECTURE.md` : description technique détaillée du conteneur, des ports, de la persistance et du cycle de vie.
- `dockerfile` : image basée sur Node.js 24, avec les outils système nécessaires et Pi Coding Agent installé globalement.
- `docker-compose.yml` : définition du service, des ressources et des volumes persistants.
- `project_code/` : espace de travail partagé avec le conteneur (`/workspace`).
- `root_home/` : dossier personnel local monté dans `/root`, contenant notamment la configuration, l’authentification et les sessions Pi dans `root_home/.pi/`. Il est exclu du dépôt.
