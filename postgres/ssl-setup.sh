#!/bin/bash
set -e

DOMAIN="${PG_DOMAIN:-}"
CERT_DIR="/etc/letsencrypt/live/${DOMAIN}"

if [ -z "$DOMAIN" ]; then
  echo "[SSL] No PG_DOMAIN set, skipping SSL setup."
  exit 0
fi

echo "[SSL] Waiting for Let's Encrypt certificate..."
for i in $(seq 1 30); do
  if [ -f "${CERT_DIR}/fullchain.pem" ]; then
    break
  fi
  echo "[SSL] Waiting... (${i}/30)"
  sleep 5
done

if [ ! -f "${CERT_DIR}/fullchain.pem" ]; then
  echo "[SSL] WARNING: Certificate not found after 150s. Running without SSL."
  exit 0
fi

cp "${CERT_DIR}/fullchain.pem" /var/lib/postgresql/server.crt
cp "${CERT_DIR}/privkey.pem" /var/lib/postgresql/server.key
chown postgres:postgres /var/lib/postgresql/server.crt /var/lib/postgresql/server.key
chmod 600 /var/lib/postgresql/server.key

cat >> /var/lib/postgresql/data/postgresql.conf <<SSLCONF
ssl = on
ssl_cert_file = '/var/lib/postgresql/server.crt'
ssl_key_file = '/var/lib/postgresql/server.key'
SSLCONF

echo "hostssl all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf

echo "[SSL] PostgreSQL SSL configured with Let's Encrypt certificate for ${DOMAIN}"
