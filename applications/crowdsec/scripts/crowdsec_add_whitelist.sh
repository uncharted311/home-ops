#!/bin/bash

# --- KONFIGURATION ---
SECRETS_FILE="/opt/crowdsec-central/secrets.env"
DNS_V4=$(grep '^DNS_ADMIN_IPV4=' "$SECRETS_FILE" | cut -d '=' -f2-)
DNS_V6=$(grep '^DNS_ADMIN_IPV6=' "$SECRETS_FILE" | cut -d '=' -f2-)

REASON_V4="Dynamic Admin Home IPv4"
REASON_V6="Dynamic Admin Home IPv6"

DB_FILE_V4="/tmp/last_admin_ip_v4.txt"
DB_FILE_V6="/tmp/last_admin_ip_v6.txt"

# Diese Datei enthält NUR die dynamischen Erlaubnisse
NGINX_CONF="/opt/crowdsec-central/nginx/whitelist_admin.conf"

CONTAINER_CROWDSEC="crowdsec"
CONTAINER_DB="crowdsec-db"
CONTAINER_NGINX="nginx"
DURATION="8760h"
# ---------------------

get_ip() {
    local dns=$1
    local type=$2
    curl -s -H "accept: application/dns-json" \
         -H "cache-control: no-cache, no-store, must-revalidate" \
         "https://1.1.1.1/dns-query?name=$dns&type=$type" \
         | jq -r '.Answer[0].data' 2>/dev/null | grep -v "null" | sed 's/\.$//'
}

CURRENT_IP4=$(get_ip "$DNS_V4" "A")
CURRENT_IP6=$(get_ip "$DNS_V6" "AAAA")

process_ip() {
    local ip=$1
    local reason=$2
    local db_file=$3
    local type_label=$4

    if [[ -z "$ip" || "$ip" == "null" ]]; then
        return 1
    fi

    local last_ip=$(cat "$db_file" 2>/dev/null)

    # 1. Altes löschen, wenn IP sich geändert hat
    if [[ "$ip" != "$last_ip" && -n "$last_ip" ]]; then
        docker exec $CONTAINER_CROWDSEC cscli decisions delete --reason "$reason" > /dev/null 2>&1
    fi

    # 2. Check ob aktuell in DB
    local wl_exists=$(docker exec $CONTAINER_DB psql -U crowdsec -d crowdsec -t -c \
    "SELECT count(*) FROM decisions WHERE value = '$ip' AND type = 'whitelist' AND scenario = '$reason';")
    wl_exists=$(echo $wl_exists | tr -d '[:space:]')

    # 3. Falls nicht da, neu setzen
    if [[ "$wl_exists" == "0" ]]; then
        docker exec $CONTAINER_CROWDSEC cscli decisions delete -i "$ip" > /dev/null 2>&1
        docker exec $CONTAINER_CROWDSEC cscli decisions add --ip "$ip" --type whitelist --reason "$reason" --duration "$DURATION"
        echo "$ip" > "$db_file"
        return 0 
    fi

    [[ "$ip" != "$last_ip" ]] && echo "$ip" > "$db_file" && return 0
    return 1
}

process_ip "$CURRENT_IP4" "$REASON_V4" "$DB_FILE_V4" "IPv4"
CHANGED_V4=$?
process_ip "$CURRENT_IP6" "$REASON_V6" "$DB_FILE_V6" "IPv6"
CHANGED_V6=$?

# 4. NGINX nur mit den DynIPs schreiben
if [[ $CHANGED_V4 -eq 0 ]] || [[ $CHANGED_V6 -eq 0 ]] || [[ ! -f "$NGINX_CONF" ]]; then
    echo "[*] Update NGINX Dyn-Whitelist..."
    mkdir -p "$(dirname "$NGINX_CONF")"
    
    {
        echo "# Dynamische Admin-IPs - Generiert $(date)"
        [[ -n "$CURRENT_IP4" ]] && echo "allow $CURRENT_IP4;"
        [[ -n "$CURRENT_IP6" ]] && echo "allow $CURRENT_IP6;"
        # KEIN 'deny all' hier, falls du diese Datei mit anderen Includes kombinierst!
    } > "$NGINX_CONF"

    if docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NGINX$"; then
        docker exec $CONTAINER_NGINX nginx -s reload
    fi
fi