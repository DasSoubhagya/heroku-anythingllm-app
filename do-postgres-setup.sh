#!/bin/bash
# DigitalOcean PostgreSQL + PGVector Setup Script
# Run this on a fresh Ubuntu 22.04/24.04 droplet (1GB RAM minimum)
#
# Usage: ssh root@your-droplet-ip 'bash -s' < do-postgres-setup.sh

set -e

DB_NAME="anythingllm"
DB_USER="anythingllm"
DB_PASS="$(openssl rand -hex 16)"

echo "========================================"
echo "  PostgreSQL + PGVector Setup"
echo "========================================"

apt-get update -qq
apt-get install -y -qq postgresql postgresql-contrib

PG_VERSION=$(pg_lsclusters -h | awk '{print $1}')

apt-get install -y -qq postgresql-${PG_VERSION}-pgvector

systemctl enable postgresql
systemctl start postgresql

sudo -u postgres psql <<SQL
CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';
CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
\c ${DB_NAME}
CREATE EXTENSION IF NOT EXISTS vector;
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
SQL

PG_HBA=$(sudo -u postgres psql -t -P format=unaligned -c "SHOW hba_file")
echo "host    ${DB_NAME}    ${DB_USER}    0.0.0.0/0    md5" >> "$PG_HBA"

PG_CONF=$(sudo -u postgres psql -t -P format=unaligned -c "SHOW config_file")
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

# Basic tuning for 1GB RAM
cat >> "$PG_CONF" <<TUNE
# AnythingLLM tuning for 1GB RAM
shared_buffers = 256MB
effective_cache_size = 512MB
work_mem = 4MB
maintenance_work_mem = 64MB
max_connections = 50
TUNE

systemctl restart postgresql

# Set up UFW firewall
ufw allow OpenSSH
ufw allow 5432/tcp
ufw --force enable

echo ""
echo "========================================"
echo "  Setup Complete!"
echo "========================================"
echo ""
echo "Connection details:"
echo "  Host:     $(curl -s ifconfig.me)"
echo "  Port:     5432"
echo "  Database: ${DB_NAME}"
echo "  User:     ${DB_USER}"
echo "  Password: ${DB_PASS}"
echo ""
echo "DATABASE_URL:"
echo "  postgresql://${DB_USER}:${DB_PASS}@$(curl -s ifconfig.me):5432/${DB_NAME}"
echo ""
echo "Set this on Heroku:"
echo "  heroku config:set DATABASE_URL=\"postgresql://${DB_USER}:${DB_PASS}@$(curl -s ifconfig.me):5432/${DB_NAME}\" -a anything-llm-app"
echo ""
echo "SAVE THESE CREDENTIALS - they won't be shown again!"
echo "========================================"
