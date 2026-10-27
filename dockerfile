FROM node:24-bookworm-slim

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    bash \
    git \
    curl \
    openssh-server \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Installation globale officielle de l'agent Pi
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

WORKDIR /workspace

# Démarre le serveur SSH au premier plan pour maintenir le conteneur actif
RUN mkdir -p /run/sshd
CMD ["/bin/bash", "-lc", "echo \"root:${ROOT_PASSWORD:?La variable ROOT_PASSWORD est obligatoire}\" | chpasswd && ssh-keygen -A && exec /usr/sbin/sshd -D -e -o PermitRootLogin=yes -o PasswordAuthentication=yes -o PubkeyAuthentication=yes"]
