# Architecture technique

## Objectif et principes

`pi-sand-box` fournit un environnement de développement isolé dans un conteneur Docker. Pi Coding Agent, les outils système et les commandes lancées par l’utilisateur s’exécutent dans ce conteneur. Les projets et le dossier personnel de `root` sont montés depuis l’hôte afin de survivre à la recréation du conteneur.

Le conteneur peut être utilisé de deux façons :

- connexion interactive SSH en tant que `root` ;
- commande ponctuelle ou session interactive avec `docker exec`.

Docker Compose construit et démarre un conteneur unique. Aucun orchestrateur externe ni volume Docker nommé n’est utilisé : les données persistantes sont des bind mounts vers les répertoires du dépôt.

## Composants

### Image (`dockerfile`)

L’image part de `node:24-bookworm-slim` et installe `bash`, `git`, `curl`, `openssh-server`, Python 3 et pip. Pi Coding Agent est installé globalement par npm avec les scripts d’installation ignorés. Le répertoire de travail par défaut est `/workspace`.

Au démarrage, la commande du conteneur :

1. exige la variable `ROOT_PASSWORD` et définit le mot de passe du compte `root` avec `chpasswd` ;
2. crée les clés d’hôte SSH manquantes avec `ssh-keygen -A` ;
3. démarre `sshd` au premier plan, ce qui maintient le conteneur actif.

Le serveur autorise l’accès SSH de `root` par mot de passe et par clé publique. Les clés publiques autorisées sont celles présentes dans `/root/.ssh/authorized_keys`. Aucune commande de démarrage ne configure un utilisateur non privilégié.

### Service Docker Compose (`docker-compose.yml`)

Le service Compose s’appelle `pi-agent-sandbox`. Son conteneur porte le nom `pi_coding_sandbox` et le nom d’hôte `dev-container` ; ce dernier est celui que le shell SSH utilise dans son prompt. La politique de redémarrage est `unless-stopped`. Les limites déclarées sont de 2 CPU et 2 Go de mémoire.

Compose transmet `NODE_ENV=development` ainsi que `ROOT_PASSWORD`, lu dans l’environnement ou dans le fichier `.env`. La substitution est obligatoire : Compose refuse de construire la configuration si `ROOT_PASSWORD` n’est pas défini.

### Configuration du secret (`.env.sample` et `.env`)

`.env.sample` est un modèle versionnable qui contient un mot de passe fictif. Il ne doit pas être utilisé tel quel. L’utilisateur le copie en `.env` et remplace cette valeur, ou génère un secret aléatoire. `.env` est exclu de Git par les règles d’ignorance.

Le mot de passe est transmis comme variable d’environnement au conteneur et appliqué au compte `root` au démarrage. Toute personne ayant accès au daemon Docker ou aux paramètres du conteneur peut potentiellement consulter cette variable : l’accès au daemon Docker doit donc être protégé.

## Réseau

Tous les ports publiés sont liés explicitement à `0.0.0.0`, donc exposés sur toutes les interfaces IPv4 de l’hôte :

| Port hôte | Port conteneur | Usage |
| --- | ---: | --- |
| `2222` | `22` | SSH vers le compte `root` |
| `8080` | `8080` | Applications de développement |
| `8081` | `8081` | Applications de développement |
| `8090` | `8090` | Applications de développement |
| `8091` | `8091` | Applications de développement |
| `3000` | `3000` | Applications de développement |
| `3001` | `3001` | Applications de développement |

La connexion SSH depuis un client utilise par exemple `ssh -p 2222 root@<adresse-ip-hote>`. Pour que les services web soient joignables depuis l’extérieur du conteneur, les applications doivent écouter sur `0.0.0.0` dans le conteneur, et non uniquement sur `127.0.0.1`.

La publication sur toutes les interfaces ne garantit pas que le réseau ou le pare-feu autorise les connexions. Elle rend néanmoins ces ports accessibles là où le réseau le permet. Il faut protéger l’accès par un mot de passe robuste, préférer les clés SSH et filtrer les connexions avec le pare-feu de l’hôte.

## Persistance et correspondance des chemins

| Chemin sur l’hôte | Chemin dans le conteneur | Contenu |
| --- | --- | --- |
| `project_code/` | `/workspace` | Projets et fichiers de travail |
| `root_home/` | `/root` | Dossier personnel complet de `root` |
| `root_home/.pi/` | `/root/.pi/` | Réglages Pi, authentification, sessions et état de l’agent |
| `root_home/.ssh/authorized_keys` | `/root/.ssh/authorized_keys` | Clés publiques autorisées pour SSH |

Les modifications dans ces répertoires sont immédiatement visibles des deux côtés. Le montage actuel de `root_home/` sur `/root` est l’unique emplacement persistant pour le dossier personnel du conteneur.

`root_home/` est exclu de Git car il peut contenir des secrets et des données locales. `.env` est également ignoré. À l’inverse, `.env.sample` est destiné à être versionné. Les autres fichiers du système, dont `/etc/shadow`, les fichiers installés par apt/npm et les clés d’hôte SSH, résident dans la couche du conteneur et ne sont pas sauvegardés par ces bind mounts.

Une reconstruction d’image suivie d’une recréation du conteneur conserve les bind mounts, mais réinitialise les fichiers non persistés de son système. Les clés d’hôte SSH sont générées si elles manquent dans le conteneur ; elles peuvent donc changer lors d’une recréation, ce qui peut provoquer un avertissement de clé d’hôte côté client SSH.

## Cycle de vie

1. `docker compose up -d --build` construit l’image si nécessaire puis crée/démarre le conteneur.
2. Docker applique le hostname, les limites, les ports et les montages définis par Compose.
3. La commande de démarrage définit le mot de passe de `root`, génère au besoin les clés d’hôte et lance `sshd`.
4. Le client se connecte en SSH au port hôte `2222`, ou lance Pi/un shell avec `docker exec`.
5. Les fichiers de `/workspace` et de `/root` sont conservés dans leurs dossiers locaux respectifs, même après `docker compose down` puis une nouvelle création du conteneur.

Commandes courantes :

```bash
# Construire et démarrer
docker compose up -d --build

# Consulter l’état
docker compose ps

# Ouvrir Pi ou un shell sans SSH
docker exec -it pi_coding_sandbox pi
docker exec -it pi_coding_sandbox bash

# Arrêter et supprimer le conteneur (les bind mounts locaux restent)
docker compose down
```

## Limites et précautions

- Le conteneur tourne sous `root` et l’isolation Docker n’est pas une frontière de sécurité aussi forte qu’une machine virtuelle. N’y exécutez pas de code non fiable sans précautions.
- L’accès SSH par mot de passe est activé en plus des clés ; choisissez un mot de passe unique et robuste. `.env` et les dossiers personnels ne doivent pas être publiés.
- Les ports SSH et de développement sont exposés sur `0.0.0.0`. Restreignez-les par pare-feu si le conteneur ne doit pas être accessible sur tous les réseaux.
- Les données persistantes sont des dossiers de l’hôte. Leur propriétaire et leurs permissions peuvent affecter l’accès depuis le conteneur.
- La configuration est installée dans l’image ; après modification du `dockerfile`, reconstruisez avec `docker compose up -d --build`.
