#!/bin/sh
set -e

# Prüfen, ob smbclient bereits installiert ist
if ! command -v smbclient >/dev/null 2>&1; then
    echo "Installiere SMB Abhängigkeiten..."
    apt-get update
    apt-get install -y libsmbclient-dev smbclient
    
    # PECL Erweiterung installieren, falls nicht vorhanden
    if ! php -m | grep -q 'smbclient'; then
        pecl install smbclient
        docker-php-ext-enable smbclient
    fi
    
    # Aufräumen spart Platz im Layer (auch wenn es kein Build ist)
    rm -rf /var/lib/apt/lists/*
else
    echo "SMB bereits installiert, überspringe..."
fi