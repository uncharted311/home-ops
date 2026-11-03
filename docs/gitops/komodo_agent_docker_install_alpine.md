HOSTNAME=$(hostname -f)

# Community-Repository aktivieren (falls noch auskommentiert) und Pakete installieren
sed -i 's/^#\(.*\/community\)/\1/' /etc/apk/repositories
apk update
apk add docker docker-cli-compose git ca-certificates curl

# Dienste im OpenRC-Autostart verankern
rc-update add cgroups boot
rc-update add docker default
rc-update add crond default

# Dienste sofort starten
rc-service cgroups start
rc-service docker start
rc-service crond start

mkdir -p /etc/komodo /opt/komodo-agent
cd /opt/komodo-agent

cat << EOF > /opt/komodo-agent/.env
PERIPHERY_CORE_PUBLIC_KEYS=MCowBQYDK2VuAyEA/LCYwDiBxrMYOZdqbntwPoIPHZ7CKpCAOmQQT6JnOyA=
PERIPHERY_ALLOWED_IPS=172.16.10.18
EOF

chmod 600 /opt/komodo-agent/.env

cat << EOF > /opt/komodo-agent/compose.yaml
services:
  periphery:
    image: ghcr.io/moghtech/komodo-periphery:2.3
    container_name: komodo-periphery
    init: true
    restart: unless-stopped
    ports:
      - "8120:8120"
    env_file:
      - .env
    labels:
      komodo.skip: ""
    environment:
      PERIPHERY_ROOT_DIRECTORY: /etc/komodo
      PERIPHERY_SSL_ENABLED: "true"
      PERIPHERY_CORE_PUBLIC_KEYS: ${PERIPHERY_CORE_PUBLIC_KEYS}
      PERIPHERY_ALLOWED_IPS: ${PERIPHERY_ALLOWED_IPS}
      PERIPHERY_DISABLE_TERMINALS: "true"
      PERIPHERY_DISABLE_CONTAINER_TERMINALS: "true"
    volumes:
      - periphery-keys:/config/keys
      - /var/run/docker.sock:/var/run/docker.sock
      - /proc:/proc
      - /etc/komodo:/etc/komodo

volumes:
  periphery-keys:
EOF


docker compose up -d
docker compose logs -f