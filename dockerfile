FROM node:24-bookworm-slim

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    bash \
    git \
    curl \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Installation globale officielle de l'agent Pi
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

WORKDIR /workspace

# Commande par défaut pour maintenir le conteneur éveillé
CMD ["tail", "-f", "/dev/null"]
