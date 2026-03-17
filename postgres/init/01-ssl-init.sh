#!/bin/bash
set -e

echo "[SSL] Generating self-signed certificate for PostgreSQL..."

openssl req -new -x509 -days 3650 -nodes \
  -out /var/lib/postgresql/data/server.crt \
  -keyout /var/lib/postgresql/data/server.key \
  -subj "/CN=shared-postgres"

chown postgres:postgres /var/lib/postgresql/data/server.crt /var/lib/postgresql/data/server.key
chmod 600 /var/lib/postgresql/data/server.key

echo "ssl = on" >> /var/lib/postgresql/data/postgresql.conf
echo "hostssl all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf

echo "[SSL] PostgreSQL SSL enabled with self-signed certificate."
