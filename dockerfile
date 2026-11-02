FROM node:24-bookworm-slim

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    bash \
    btop \
    git \
    htop \
    nano \
    curl \
    openssh-server \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Installation globale officielle de l'agent Pi
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# Les exécutables npm installés dans le préfixe local de root restent accessibles.
# /root est monté depuis l'hôte : les installations sont faites au démarrage,
# après le montage, pour qu'elles soient persistées dans ce volume.
ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /workspace

# Démarre le serveur SSH au premier plan pour maintenir le conteneur actif
RUN mkdir -p /run/sshd
CMD ["/bin/bash", "-lc", "grep -qxF 'export PATH=\"/root/.local/bin:$PATH\"' /root/.profile 2>/dev/null || printf '%s\\n' 'export PATH=\"/root/.local/bin:$PATH\"' >> /root/.profile; npm install -g billion-context --prefix=/root/.local && pi install npm:pi-hermes-memory && echo \"root:${ROOT_PASSWORD:?La variable ROOT_PASSWORD est obligatoire}\" | chpasswd && ssh-keygen -A && exec /usr/sbin/sshd -D -e -o PermitRootLogin=yes -o PasswordAuthentication=yes -o PubkeyAuthentication=yes"]
