#!/bin/bash
# Pfad: /usr/local/bin/crowdsec_housekeeping.sh

DB_CONTAINER="crowdsec-db"
DB_USER="crowdsec"
DB_NAME="crowdsec"
ALERT_RETENTION_DAYS="7"

exec_sql() {
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "$1"
}

{
echo "===================================================="
echo "START CLEANUP: $(date)"
echo "===================================================="

# 1. ABGELAUFENE ENTSCHEIDUNGEN (Das Wichtigste)
echo "[1/7] Lösche abgelaufene Entscheidungen..."
exec_sql "DELETE FROM decisions WHERE until < now();"

# 2. ALTE ALERTS
echo "[2/7] Lösche Alerts älter als $ALERT_RETENTION_DAYS Tage..."
exec_sql "DELETE FROM alerts WHERE created_at < now() - interval '$ALERT_RETENTION_DAYS days';"

# 2.5 DEDUPLIZIERUNG
echo "[2.5/7] Entferne IP-Dubletten..."
exec_sql "DELETE FROM decisions WHERE id IN (SELECT id FROM (SELECT id, ROW_NUMBER() OVER (PARTITION BY value ORDER BY until DESC) as row_num FROM decisions WHERE origin IN ('lists', 'blocklist-import', 'cscli-import')) t WHERE t.row_num > 1);"

# 3. IMPORT-ALERTS
echo "[3/7] Entferne Import-Alert-Reste..."
exec_sql "DELETE FROM alerts WHERE scenario LIKE 'import %' OR scenario LIKE 'borestad%' OR scenario LIKE 'external/blocklist%';"

# 4. DYNAMISCHES EVENT-CLEANUP
echo "[4/7] Bereinige verwaiste Events..."
COL_NAME=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c \
"SELECT column_name FROM information_schema.columns WHERE table_name='events' AND column_name IN ('alert_id', 'id_alert') LIMIT 1;" | xargs)

if [ -n "$COL_NAME" ]; then
    echo "    (Nutze Spalte: $COL_NAME)"
    exec_sql "DELETE FROM events WHERE $COL_NAME NOT IN (SELECT id FROM alerts) OR $COL_NAME IS NULL;"
else
    echo "    (INFO: Keine bekannte Referenzspalte in 'events' gefunden, überspringe.)"
fi

# 5. INDEX-MANAGEMENT
echo "[5/7] Optimiere Indizes..."
exec_sql "ANALYZE decisions; ANALYZE alerts; ANALYZE events;"

# 6. SPEICHER-OPTIMIERUNG
echo "[6/7] Führe schonendes Vacuum aus..."
exec_sql "VACUUM decisions;"
exec_sql "VACUUM alerts;"
exec_sql "VACUUM events;"

# 7. STATUS-BERICHT
echo "[7/7] Datenbank-Statistik:"
exec_sql "SELECT relname as Tabelle, pg_size_pretty(pg_total_relation_size(relid)) as Groesse FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC;"

echo "===================================================="
echo "CLEANUP BEENDET: $(date)"
echo "===================================================="

echo "Aktive Entscheidungen nach Herkunft:"
exec_sql "SELECT origin, count(*) FROM decisions GROUP BY origin;"

} >> /var/log/crowdsec_cleanup.log 2>&1