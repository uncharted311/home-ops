#!/bin/sh
set -e
# 
# -------------------------------------------- README --------------------------------------------
# SECRET_DOMAIN=> (Main-Domain for Certbot-Path /live/)
# optional SECRET_CERT_DOMAINS=> Commaseparted list for multiple Domains "example.comf,*.example.com"
# SECRET_ADMIN_EMAIL=> Admin E-Mail
#
# 1. Example for Wildcards
#
#   Docker-environment:
#      - SECRET_DOMAIN=example.com
#      - SECRET_CERT_NAME=srv.example.com
#      - SECRET_CERT_DOMAINS=srv.example.com,*.srv.example.com
#      - SECRET_ADMIN_EMAIL=${SECRET_ADMIN_EMAIL}
# 
# 2. Example for Single Domains:
#
#    Docker-environment:
#      - SECRET_DOMAIN=example.com
#      - SECRET_CERT_NAME=auth.example.com
#      - SECRET_CERT_DOMAINS=auth.example.com,ldap.example.com
#      - SECRET_ADMIN_EMAIL=${SECRET_ADMIN_EMAIL}
# ------------------------------------------------------------------------------------------------

NAME="${SECRET_CERT_NAME:-$SECRET_DOMAIN}"
DOMAINS="${SECRET_CERT_DOMAINS:-$NAME}"
EMAIL="${SECRET_ADMIN_EMAIL}"

if [ -z "$NAME" ] || [ -z "$EMAIL" ]; then
    echo "FEHLER: CERT_NAME (oder SECRET_DOMAIN) und SECRET_ADMIN_EMAIL müssen gesetzt sein!"
    exit 1
fi

# Build -d Argument for certbot
# "a.com,b.com" splitt to "-d a.com -d b.com"
CERT_ARGS=""
for d in $(echo "$DOMAINS" | tr "," "\n"); do
    CERT_ARGS="$CERT_ARGS -d $d"
done

CERT_PATH="/etc/letsencrypt/live/$NAME/fullchain.pem"

echo "--- Certbot Manager ---"
echo "Zertifikats-Name: $NAME"
echo "Enthaltene Domains: $DOMAINS"

if [ ! -f "$CERT_PATH" ]; then
    echo "Initialisiere neues Zertifikat..."
    certbot certonly \
      --dns-cloudflare \
      --dns-cloudflare-credentials /cloudflare.ini \
      --dns-cloudflare-propagation-seconds 30 \
      --agree-tos \
      --no-eff-email \
      -m "$EMAIL" \
      --cert-name "$NAME" \
      $CERT_ARGS \
      --non-interactive
else
    echo "Zertifikat vorhanden. Prüfe auf Erneuerung..."
    certbot renew \
      --dns-cloudflare \
      --dns-cloudflare-credentials /cloudflare.ini \
      --dns-cloudflare-propagation-seconds 30 \
      --non-interactive
fi

echo "Certbot abgeschlossen. Gehe in den Wartemodus."
exec sleep infinity