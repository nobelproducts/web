#!/bin/bash
# Renew Let's Encrypt certificates for all websites.
# Run via crontab every 60 days, e.g.:
#   0 3 */60 * * /root/nobelproducts/renew-certs.sh >> /var/log/renew-certs.log 2>&1
#
# Flow: stop nginx → renew all certs → start nginx → verify each cert is valid

set -euo pipefail

COMPOSE_DIR="/root/nobelproducts"
LOG_PREFIX="[renew-certs]"

DOMAINS=(
  "dragonscreenservice.com"
  "fenixscreen.com"
  "gustexscreen.com"
  "hotprintscreen.com"
  "turboscreenprint.com"
  "flashscreendtf.com"
)

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') ${LOG_PREFIX} $*"
}

# ── 1. Stop nginx to free port 80 ─────────────────────────────────────────────

log "Stopping nginx container..."
cd "$COMPOSE_DIR"
docker compose stop nginx
log "nginx stopped."

# ── 2. Renew all certificates ─────────────────────────────────────────────────

log "Running certbot renew (standalone)..."
certbot renew \
  --standalone \
  --non-interactive \
  --quiet
log "certbot renew completed."

# ── 3. Start nginx ────────────────────────────────────────────────────────────

log "Starting nginx container..."
docker compose start nginx
sleep 5   # give nginx a moment to fully initialise
log "nginx started."

# ── 4. Verify each certificate is still valid ─────────────────────────────────

FAILED=()

for DOMAIN in "${DOMAINS[@]}"; do
  CERT="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"

  if [ ! -f "$CERT" ]; then
    log "WARN  ${DOMAIN} — cert file not found: ${CERT}"
    FAILED+=("$DOMAIN")
    continue
  fi

  # Days remaining until expiry
  EXPIRY=$(openssl x509 -enddate -noout -in "$CERT" | cut -d= -f2)
  EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$EXPIRY" +%s)
  NOW_EPOCH=$(date +%s)
  DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

  # Also verify the cert is reachable via HTTPS (port 443)
  TLS_OK="OK"
  if ! echo | openssl s_client -connect "${DOMAIN}:443" -servername "$DOMAIN" \
       -verify_return_error 2>/dev/null | grep -q "Verify return code: 0"; then
    TLS_OK="FAIL"
  fi

  if [ "$TLS_OK" = "OK" ] && [ "$DAYS_LEFT" -gt 0 ]; then
    log "OK    ${DOMAIN} — expires in ${DAYS_LEFT} day(s)  [TLS handshake: ${TLS_OK}]"
  else
    log "FAIL  ${DOMAIN} — expires in ${DAYS_LEFT} day(s)  [TLS handshake: ${TLS_OK}]"
    FAILED+=("$DOMAIN")
  fi
done

# ── 5. Final summary ──────────────────────────────────────────────────────────

echo ""
if [ ${#FAILED[@]} -eq 0 ]; then
  log "All certificates are valid. Renewal complete."
  exit 0
else
  log "WARNING: The following domains have issues:"
  for D in "${FAILED[@]}"; do
    log "  - ${D}"
  done
  exit 1
fi
