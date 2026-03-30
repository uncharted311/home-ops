#!/usr/bin/env bash
# removeWrongPasswords from NZB-Files
sed -i '0,/<meta type="password">/{s/-distribution-not-allowed-//}' "$1"