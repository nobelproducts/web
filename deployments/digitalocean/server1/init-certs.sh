#!/bin/bash
# Run this script ONCE on the server BEFORE starting docker compose.
# It installs certbot and obtains Let's Encrypt certs for all 6 domains
# using standalone mode (temporarily binds to port 80 — no nginx running yet).
#
# Usage:
#   chmod +x init-certs.sh
#   ./init-certs.sh your@email.com

set -e

EMAIL="${1:?Usage: $0 <email>}"

DOMAINS=(
  "dragonscreenservice.com www.dragonscreenservice.com"
  "fenixscreen.com www.fenixscreen.com"
  "gustexscreen.com www.gustexscreen.com"
  "hotprintscreen.com www.hotprintscreen.com"
  "turboscreenprint.com www.turboscreenprint.com"
  "flashscreendtf.com www.flashscreendtf.com"
)

# Install certbot if not present
if ! command -v certbot &>/dev/null; then
  echo "Installing certbot..."
  apt-get update -qq
  apt-get install -y certbot
fi

# Stop nginx container if running (frees port 80 for standalone mode)
if docker ps --format '{{.Names}}' | grep -q '^nginx$'; then
  echo "Stopping nginx container to free port 80..."
  docker stop nginx
fi

# Obtain certs for each domain
for DOMAIN_LINE in "${DOMAINS[@]}"; do
  read -ra PARTS <<< "$DOMAIN_LINE"
  PRIMARY="${PARTS[0]}"
  DOMAIN_ARGS=()
  for D in "${PARTS[@]}"; do
    DOMAIN_ARGS+=(-d "$D")
  done

  if [ -f "/etc/letsencrypt/live/${PRIMARY}/fullchain.pem" ]; then
    echo "Certificate already exists for ${PRIMARY}, skipping."
  else
    echo "Obtaining certificate for ${PRIMARY}..."
    certbot certonly \
      --standalone \
      --non-interactive \
      --agree-tos \
      --email "$EMAIL" \
      "${DOMAIN_ARGS[@]}"
  fi
done

echo ""
echo "All certificates obtained. Starting docker compose..."
docker compose up -d
echo "Done."
