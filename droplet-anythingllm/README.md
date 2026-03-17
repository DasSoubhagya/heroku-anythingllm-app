# Fresh AnythingLLM on single droplet

This folder is a minimal deployment for running only AnythingLLM on one droplet.

## 1) Run setup on droplet

```bash
chmod +x /opt/anythingllm/droplet-anythingllm/setup.sh
sudo /opt/anythingllm/droplet-anythingllm/setup.sh
```

Or if repo not cloned yet:

```bash
git clone https://github.com/DasSoubhagya/heroku-anythingllm-app.git /opt/anythingllm
chmod +x /opt/anythingllm/droplet-anythingllm/setup.sh
sudo /opt/anythingllm/droplet-anythingllm/setup.sh
```

## 2) Edit env

```bash
nano /opt/anythingllm/droplet-anythingllm/.env
```

Set at minimum:
- `AUTH_TOKEN`
- `JWT_SECRET`
- `GENERIC_OPEN_AI_KEY`

## 3) Restart after edits

```bash
cd /opt/anythingllm/droplet-anythingllm
docker compose up -d
```

## Cloudflare Tunnel recommendation

### Best for your case: run cloudflared on host
- Simpler for one app
- Survives container recreation
- Easier to debug and upgrade

### Container is also valid if you want all-in-docker
- Good when you manage all services in compose
- Slightly more moving parts for tunnel credentials

Because `docker-compose.yml` binds AnythingLLM to `127.0.0.1:3001`, app is not directly public; Cloudflare Tunnel can safely expose it.
