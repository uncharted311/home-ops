apt update
apt install -y git openssl curl gawk coreutils grep jq
curl -sSL https://get.docker.com/ | CHANNEL=stable sh
systemctl enable --now docker
