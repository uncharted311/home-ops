curl -sSL https://raw.githubusercontent.com/moghtech/komodo/main/scripts/setup-periphery.py | python3

add Passkey for Komodo
add allowed_ips = ["172.16.10.18"]
nano /etc/komodo/periphery.config.toml

sudo systemctl enable --now periphery.service
sudo systemctl restart periphery.service


## Optional. Require callers to provide on of the provided passkeys to access the periphery api.
## Example: passkeys = ["your-passkey"]
## Env: PERIPHERY_PASSKEYS or PERIPHERY_PASSKEYS_FILE
## Default: empty, which will not require any passkey to be passed by core.
passkeys = []

## Accepted public keys to allow Core(s) to connect.
## Periphery gains knowledge of the Core public key through the noise handshake.
## If neither these nor passkeys provided, inbound connections will not be authenticated.
## Accepts Spki base64 DER directly and PEM file. Use `file:/path/to/core.pub` to load from file.
## Env: PERIPHERY_CORE_PUBLIC_KEYS - PERIPHERY_CORE_PUBLIC_KEYS: "MCowBQYDK2VuAyEA/LCYwDiBxrMYOZdqbntwPoIPHZ7CKpCAOmQQT6JnOyA="
## Optional, no default.
core_public_keys = "MCowBQYDK2VuAyEA/LCYwDiBxrMYOZdqbntwPoIPHZ7CKpCAOmQQT6JnOyA="







