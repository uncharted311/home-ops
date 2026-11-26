#!/bin/sh
set -e
#
# -------------------------------------------- README --------------------------------------------
# SECRET_DOMAIN=> (Main-Domain for Certbot-Path /live/ if SECRET_CERT_NAME is not set)
# optional SECRET_CERT_NAME=> Custom Certbot-Path /live/<SECRET_CERT_NAME>
# optional SECRET_CERT_DOMAINS=> Commaseparated list for multiple Domains "example.com,*.example.com"
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

CERT_NAME="${CERT_NAME:-${SECRET_CERT_NAME:-${SECRET_DOMAIN:-}}}"
DOMAINS_LIST="${SECRET_CERT_DOMAINS:-${SECRET_DOMAIN:-$CERT_NAME}}"

EMAIL="${SECRET_ADMIN_EMAIL:-}"
TOKEN="${CF_API_TOKEN:-${SECRET_CLOUDFLARE_API_TOKEN:-}}"

if [ -z "$CERT_NAME" ] || [ -z "$DOMAINS_LIST" ] || [ -z "$EMAIL" ]; then
  echo "FEHLER: SECRET_CERT_NAME (oder SECRET_DOMAIN) und SECRET_ADMIN_EMAIL müssen gesetzt sein!" >&2
  exit 1
fi

if [ -z "$TOKEN" ]; then
  echo "FEHLER: CF_API_TOKEN (bzw. SECRET_CLOUDFLARE_API_TOKEN) muss gesetzt sein!" >&2
  exit 1
fi

CF_INI="/tmp/cloudflare.ini"
umask 077
printf 'dns_cloudflare_api_token = %s\n' "$TOKEN" > "$CF_INI"

set --
OLD_IFS="$IFS"
IFS=','
for d in $DOMAINS_LIST; do
  d_clean=$(printf '%s' "$d" | tr -d ' ')
  if [ -n "$d_clean" ]; then
    set -- "$@" -d "$d_clean"
  fi
done
IFS="$OLD_IFS"

if [ ! -f "/etc/letsencrypt/live/${CERT_NAME}/fullchain.pem" ]; then
  echo "Erstelle Zertifikat '${CERT_NAME}' für Domains: ${DOMAINS_LIST}"
  certbot certonly \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    --dns-cloudflare \
    --dns-cloudflare-credentials "$CF_INI" \
    --dns-cloudflare-propagation-seconds 30 \
    --cert-name "$CERT_NAME" \
    "$@"
fi

while true; do
  certbot renew \
    --non-interactive \
    --dns-cloudflare \
    --dns-cloudflare-credentials "$CF_INI" \
    --dns-cloudflare-propagation-seconds 30
  sleep 12h
done
