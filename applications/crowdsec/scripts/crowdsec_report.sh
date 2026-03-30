#!/bin/bash
# Pfad: /usr/local/bin/crowdsec_report.sh

DB_CONTAINER="crowdsec-db"
DB_USER="crowdsec"
DB_NAME="crowdsec"
DISCORD_URL=$(grep '^REPORT_DISCORD_URL=' /opt/crowdsec-central/secrets.env | cut -d '=' -f2-)

exec_sql() {
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -A -c "$1"
}

# --- Daten sammeln ---
TOTAL_DECISIONS=$(exec_sql "SELECT count(*) FROM decisions;")
DB_SIZE=$(exec_sql "SELECT pg_size_pretty(pg_database_size('$DB_NAME'));")

# Statistiken aufbereiten (Original-Format mit Bulletpoints)
ORIGIN_STATS=$(exec_sql "SELECT origin || ': ' || count(*) FROM decisions GROUP BY origin ORDER BY count(*) DESC;" | sed ':a;N;$!ba;s/\n/\\n• /g' | sed 's/^/• /')
TOP_SCENARIOS=$(exec_sql "SELECT scenario || ' (' || count(*) || ')' FROM alerts WHERE created_at > now() - interval '24 hours' GROUP BY scenario ORDER BY count(*) DESC LIMIT 5;" | sed ':a;N;$!ba;s/\n/\\n• /g' | sed 's/^/• /')
TOP_IPS=$(exec_sql "SELECT value || ' (' || count(*) || ')' FROM decisions WHERE origin = 'crowdsec' GROUP BY value ORDER BY count(*) DESC LIMIT 5;" | sed ':a;N;$!ba;s/\n/\\n• /g' | sed 's/^/• /')
# Top 3 Listen-Szenarien
TOP_LISTS=$(exec_sql "SELECT scenario || ': ' || count(*) FROM decisions WHERE origin = 'blocklist-import' GROUP BY scenario ORDER BY count(*) DESC LIMIT 3;" | sed ':a;N;$!ba;s/\n/\\n• /g' | sed 's/^/• /')

PAYLOAD=$(cat <<EOF
{
  "username": "CrowdSec-Reporter",
  "embeds": [{
    "title": "📊 Täglicher Statusbericht: oc-arm2",
    "description": "Die Datenbank belegt aktuell **$DB_SIZE** Speicherkapazität.",
    "color": 3447003,
    "fields": [
      { "name": "📈 Aktive Decisions ($TOTAL_DECISIONS Gesamt)", "value": "$ORIGIN_STATS", "inline": false },
      { "name": "🔥 Top 5 Szenarien (24h)", "value": "$TOP_SCENARIOS", "inline": false },
      { "name": "🎯 Top 5 Angreifer-IPs", "value": "$TOP_IPS", "inline": false }
    ],
    "footer": { "text": "Hausputz & Reporting aktiv | $(date '+%d.%m.%Y %H:%M')" }
  }]
}
EOF
)

curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$DISCORD_URL"