#!/usr/bin/env bash
# Generate self-signed certs in the certbot-style layout for local
# Mac testing of deploy_secure. Production uses real certbot certs —
# this script is purely for verifying the nginx config locally.
#
# Produces:
#   ./live/app.polyglots.social/fullchain.pem  (SAN: www, app, dashboard)
#   ./live/app.polyglots.social/privkey.pem
#   ./options-ssl-nginx.conf                   (copy of certbot defaults)
#   ./ssl-dhparams.pem                         (2048-bit, ~10s on a fast box)
#
# Usage:
#   cd deploy_secure/certs
#   ./generate-local.sh
set -euo pipefail
cd "$(dirname "$0")"

LIVE_DIR="./live/app.polyglots.social"
mkdir -p "$LIVE_DIR"

if [[ -f "$LIVE_DIR/fullchain.pem" && -f "$LIVE_DIR/privkey.pem" ]]; then
    echo "[skip] $LIVE_DIR already has a cert; remove it to regenerate."
else
    echo "[1/3] Generating self-signed cert with SANs for all three subdomains…"
    openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout "$LIVE_DIR/privkey.pem" \
        -out "$LIVE_DIR/fullchain.pem" \
        -days 365 \
        -subj "/CN=app.polyglots.social/O=Polyglots Local/C=US" \
        -addext "subjectAltName=DNS:www.polyglots.social,DNS:app.polyglots.social,DNS:dashboard.polyglots.social"
fi

if [[ -f "./ssl-dhparams.pem" ]]; then
    echo "[skip] ssl-dhparams.pem already exists."
else
    echo "[2/3] Generating ssl-dhparams.pem (2048 bits — takes ~10s)…"
    openssl dhparam -out "./ssl-dhparams.pem" 2048
fi

# Copy of certbot's default options-ssl-nginx.conf (TLS 1.2/1.3 only,
# Mozilla intermediate cipher list). Matches what `certbot --nginx`
# drops on a real server so the production config is identical.
cat > ./options-ssl-nginx.conf <<'EOF'
# This file contains important security parameters. If you modify this file
# manually, Certbot will be unable to automatically provide future security
# updates. Instead, Certbot will print and log an error message with a path to
# the up-to-date file that you will need to refer to when manually updating
# this file. Contents are based on https://ssl-config.mozilla.org

ssl_session_cache shared:le_nginx_SSL:10m;
ssl_session_timeout 1440m;
ssl_session_tickets off;

ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;

ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
EOF
echo "[3/3] Wrote options-ssl-nginx.conf."

echo
echo "Done. Files generated under $(pwd):"
ls -la "$LIVE_DIR" ./options-ssl-nginx.conf ./ssl-dhparams.pem
