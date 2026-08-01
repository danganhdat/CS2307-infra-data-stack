#!/usr/bin/env bash
# Run ONCE on the VM after DNS A records point at the VM's public IP.
# Handles the cert chicken-and-egg, then brings the whole stack up with TLS.
set -euo pipefail

DIR=/mnt/data/stack
cd "$DIR"

sudo bash /mnt/data/stack/render.sh
# shellcheck disable=SC1091
source "$DIR/.env"   # DOMAIN, ACME_EMAIL

CERT_LIVE=/mnt/data/certbot/conf/live/data-stack
sudo mkdir -p "$CERT_LIVE" /mnt/data/certbot/www

# 1. Temporary self-signed cert so nginx can start at all.
if [ ! -f "$CERT_LIVE/fullchain.pem" ]; then
  sudo openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
    -keyout "$CERT_LIVE/privkey.pem" -out "$CERT_LIVE/fullchain.pem" \
    -subj "/CN=localhost"
fi

# 2. Start everything (nginx now boots on the dummy cert).
sudo docker compose up -d

# 3. Swap the dummy for a real Let's Encrypt cert (one SAN cert, 3 names).
sudo rm -f "$CERT_LIVE/fullchain.pem" "$CERT_LIVE/privkey.pem"
sudo docker compose run --rm --entrypoint certbot certbot \
  certonly --webroot -w /var/www/certbot --cert-name data-stack \
  -d "neo4j.$DOMAIN" -d "console.$DOMAIN" -d "s3.$DOMAIN" \
  --email "$ACME_EMAIL" --agree-tos --no-eff-email --non-interactive

# 4. Reload nginx with the real cert.
sudo docker compose exec nginx nginx -s reload
echo "TLS is live: https://neo4j.$DOMAIN  https://console.$DOMAIN  https://s3.$DOMAIN"
