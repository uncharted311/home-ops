apt update
apt install -y git openssl curl gawk coreutils grep jq
curl -sSL https://get.docker.com/ | CHANNEL=stable sh
systemctl enable --now docker


Docker Hardening

pro Container:
cap_drop:
  - ALL
cap_add:
  - NET_BIND_SERVICE
  - CHOWN
  - SETUID
  - SETGID
read_only: true
tmpfs:
  - /tmp
  - /var/cache/nginx
  - /var/run


user: "1000:1000"
bzw.
PUID=1000
PGID=1000



 wsl bash -c "sops updatekeys -y applications/patchmgmt/secrets.sops.env"
