#!/usr/bin/env bash
set -euo pipefail

echo "[1/5] Installing Docker + Compose plugin"
apt-get update -qq
apt-get install -y -qq docker.io docker-compose-v2 curl
systemctl enable docker
systemctl start docker

echo "[2/5] Preparing app directory"
mkdir -p /opt/anythingllm
cd /opt/anythingllm

if [ ! -d .git ]; then
  echo "[3/5] Cloning repository"
  git clone https://github.com/DasSoubhagya/heroku-anythingllm-app.git .
else
  echo "[3/5] Pulling latest repository changes"
  git pull --rebase
fi

cd /opt/anythingllm/droplet-anythingllm

echo "[4/5] Preparing env files"
[ -f .env ] || cp .env.example .env
[ -f anythingllm.env ] || touch anythingllm.env

echo "[5/5] Starting AnythingLLM"
docker compose up -d

echo "Done."
echo "- Edit /opt/anythingllm/droplet-anythingllm/.env"
echo "- Restart with: cd /opt/anythingllm/droplet-anythingllm && docker compose up -d"
echo "- Local app URL: http://127.0.0.1:3001"
