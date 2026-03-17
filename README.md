# AnythingLLM Docker Deployment

Deploy [AnythingLLM](https://docs.anythingllm.com/) via Docker locally or to Heroku, with a shared PostgreSQL database backed up to Cloudflare R2.

## Project Structure

```
.
├── docker-compose.yml        # Local AnythingLLM deployment
├── Dockerfile.heroku         # Heroku container build (PG variant)
├── heroku.yml                # Heroku manifest
├── entrypoint.sh             # Heroku entrypoint (env bridge + port proxy)
├── .env.example              # AnythingLLM env template
├── postgres/                 # Shared PostgreSQL database stack
│   ├── docker-compose.yml    # PostgreSQL 16 + PGVector + backup sidecar
│   ├── .env.example          # PG + R2 credentials template
│   ├── backup/
│   │   ├── Dockerfile        # Alpine + pg-client + rclone
│   │   ├── backup.sh         # Daily pg_dumpall → R2
│   │   ├── basebackup.sh     # Weekly pg_basebackup → R2
│   │   ├── prune.sh          # Delete backups older than 7 days
│   │   └── crontab           # Cron schedule
│   └── init/
│       └── 00-extensions.sql # PGVector extension + DB setup
└── README.md
```

---

## PostgreSQL Database Server

A shared PostgreSQL 16 + PGVector container with automated backups to Cloudflare R2. Run this on any VPS (DigitalOcean, Hetzner, etc.).

### Quick Start

```bash
cd postgres
cp .env.example .env
# Edit .env: set PG_PASSWORD, R2 credentials
docker-compose up -d
```

### Backup Schedule

| Schedule | Type | What | Destination |
|----------|------|------|-------------|
| Daily 02:00 UTC | `pg_dumpall` | All databases, compressed | `r2:bucket/daily/` |
| Sunday 03:00 UTC | `pg_basebackup` | Full binary backup | `r2:bucket/weekly/` |
| After each backup | Prune | Delete files > 7 days old | -- |

### Backup File Naming

```
r2:bucket/daily/pgdump_2026-03-17_020000.sql.gz
r2:bucket/weekly/basebackup_2026-03-16_030000.tar.gz
```

### Restore from Backup

**From daily pg_dump:**

```bash
gunzip < pgdump_2026-03-17_020000.sql.gz | psql -h HOST -U anythingllm anythingllm
```

**From weekly base backup:**

```bash
docker-compose down
docker volume rm postgres_pg_data
docker volume create postgres_pg_data
# Extract base backup into the volume
docker run --rm -v postgres_pg_data:/data -v /path/to/basebackup:/backup alpine \
  sh -c "cd /data && tar xzf /backup/basebackup_*.tar.gz"
docker-compose up -d
```

### Adding More Apps

Edit `postgres/init/00-extensions.sql` to create additional databases:

```sql
CREATE DATABASE myotherapp OWNER anythingllm;
\c myotherapp
CREATE EXTENSION IF NOT EXISTS vector;
```

### Monitoring Backups

```bash
# View backup logs
docker logs pg-backup

# Manually trigger a backup
docker exec pg-backup /scripts/backup.sh

# List backups in R2
docker exec pg-backup rclone ls r2:your-bucket/daily/
```

---

## AnythingLLM: Local Docker

### Quick Start

```bash
cp .env.example .env
# Edit .env: add OpenRouter + DeepInfra API keys
docker-compose up -d
```

Open **http://localhost:3001** in your browser.

### Managing the Container

```bash
docker-compose logs -f          # View logs
docker-compose down             # Stop
docker-compose pull && docker-compose up -d   # Update
docker-compose restart          # Restart
```

---

## AnythingLLM: Heroku Deployment

### Prerequisites

- A Heroku account (container stack, Basic dyno minimum)
- The PostgreSQL server running (see above)

### Step-by-Step

**1. Create a Heroku app and set the container stack:**

```bash
heroku create your-app-name
heroku stack:set container -a your-app-name
```

**2. Set config vars (API keys + database):**

```bash
# Database (point to your VPS PostgreSQL)
heroku config:set DATABASE_URL="postgresql://anythingllm:PASSWORD@VPS_IP:5432/anythingllm" -a your-app-name

# OpenRouter
heroku config:set OPENROUTER_API_KEY=sk-or-your-key -a your-app-name
heroku config:set OPENROUTER_MODEL_PREF=openai/gpt-4o -a your-app-name

# DeepInfra
heroku config:set GENERIC_OPEN_AI_BASE_PATH=https://api.deepinfra.com/v1/openai -a your-app-name
heroku config:set GENERIC_OPEN_AI_KEY=your-deepinfra-key -a your-app-name
heroku config:set GENERIC_OPEN_AI_MODEL_PREF=meta-llama/Meta-Llama-3.1-70B-Instruct -a your-app-name
heroku config:set GENERIC_OPEN_AI_MAX_TOKENS=4096 -a your-app-name

# Password protection
heroku config:set PASSWORD_PROTECT=true -a your-app-name
heroku config:set SINGLE_USER_PASSWORD=your-secure-password -a your-app-name
```

**3. Deploy via GitHub:**

Push to GitHub, then connect the repo in Heroku Dashboard > Deploy > GitHub > Deploy Branch.

### Heroku Config Vars Reference

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string to your VPS database |
| `OPENROUTER_API_KEY` | OpenRouter API key ([get one](https://openrouter.ai/keys)) |
| `OPENROUTER_MODEL_PREF` | Default OpenRouter model (e.g. `openai/gpt-4o`) |
| `GENERIC_OPEN_AI_BASE_PATH` | DeepInfra endpoint: `https://api.deepinfra.com/v1/openai` |
| `GENERIC_OPEN_AI_KEY` | DeepInfra API key ([get one](https://deepinfra.com/dash/api_keys)) |
| `GENERIC_OPEN_AI_MODEL_PREF` | Default DeepInfra model |
| `GENERIC_OPEN_AI_MAX_TOKENS` | Max tokens (e.g. `4096`) |
| `PASSWORD_PROTECT` | Set to `true` to require login |
| `SINGLE_USER_PASSWORD` | Login password |

---

## Security

- Never commit `.env` files to version control.
- Use strong passwords for PostgreSQL and AnythingLLM.
- Restrict PostgreSQL port (5432) access via VPS firewall to only your Heroku app's IP range.
- For production, use a reverse proxy (NGINX) with SSL/TLS.
- Rotate API keys periodically.
