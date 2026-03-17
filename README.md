# AnythingLLM Docker Deployment

Deploy [AnythingLLM](https://docs.anythingllm.com/) via Docker locally or to Heroku.

## Project Structure

```
.
├── docker-compose.yml     # Local Docker deployment
├── Dockerfile.heroku      # Heroku container build
├── heroku.yml             # Heroku manifest
├── entrypoint.sh          # Heroku entrypoint (env bridge + port forwarding)
├── .env.example           # Environment variable template (all API keys/tokens)
└── README.md
```

---

## Option 1: Local Docker Deployment

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running

### Quick Start

```bash
cp .env.example .env
# Edit .env and paste your OpenRouter + DeepInfra API keys
docker-compose up -d
```

Open **http://localhost:3001** in your browser.

### Managing the Container

```bash
# View logs
docker-compose logs -f

# Stop
docker-compose down

# Update to latest version
docker-compose pull && docker-compose up -d

# Restart
docker-compose restart
```

---

## Option 2: Heroku Deployment

### Prerequisites

- [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli) installed
- A Heroku account (container stack requires at least a Basic dyno)

### Step-by-Step Deployment

**1. Create a Heroku app:**

```bash
heroku create your-app-name
```

**2. Set the stack to container:**

```bash
heroku stack:set container -a your-app-name
```

**3. Set your API tokens as config vars:**

```bash
# OpenRouter
heroku config:set OPENROUTER_API_KEY=sk-or-your-openrouter-key -a your-app-name
heroku config:set OPENROUTER_MODEL_PREF=openai/gpt-4o -a your-app-name

# DeepInfra (via Generic OpenAI-compatible endpoint)
heroku config:set GENERIC_OPEN_AI_BASE_PATH=https://api.deepinfra.com/v1/openai -a your-app-name
heroku config:set GENERIC_OPEN_AI_KEY=your-deepinfra-key -a your-app-name
heroku config:set GENERIC_OPEN_AI_MODEL_PREF=meta-llama/Meta-Llama-3.1-70B-Instruct -a your-app-name
heroku config:set GENERIC_OPEN_AI_MAX_TOKENS=4096 -a your-app-name

# Optional: password-protect the instance
heroku config:set PASSWORD_PROTECT=true -a your-app-name
heroku config:set SINGLE_USER_PASSWORD=your-secure-password -a your-app-name
```

**4. Deploy:**

```bash
git init
git add .
git commit -m "Initial AnythingLLM Heroku deployment"
heroku git:remote -a your-app-name
git push heroku main
```

**5. Open your app:**

```bash
heroku open -a your-app-name
```

### Heroku Environment Variables Reference

Set these via `heroku config:set KEY=VALUE`:

| Variable | Description |
|----------|-------------|
| `OPENROUTER_API_KEY` | OpenRouter API key ([get one here](https://openrouter.ai/keys)) |
| `OPENROUTER_MODEL_PREF` | Default model via OpenRouter (e.g. `openai/gpt-4o`) |
| `GENERIC_OPEN_AI_BASE_PATH` | DeepInfra endpoint: `https://api.deepinfra.com/v1/openai` |
| `GENERIC_OPEN_AI_KEY` | DeepInfra API key ([get one here](https://deepinfra.com/dash/api_keys)) |
| `GENERIC_OPEN_AI_MODEL_PREF` | Default DeepInfra model (e.g. `meta-llama/Meta-Llama-3.1-70B-Instruct`) |
| `GENERIC_OPEN_AI_MAX_TOKENS` | Max tokens for DeepInfra responses (e.g. `4096`) |
| `PASSWORD_PROTECT` | Set to `true` to require login |
| `SINGLE_USER_PASSWORD` | Password for single-user mode |
| `MULTI_USER_MODE` | Set to `true` for multi-user |

See `.env.example` for the complete list of supported variables.

---

## Important Notes

### Data Persistence
- **Local Docker**: Data is stored in a named Docker volume (`anythingllm_storage`) and persists across restarts.
- **Heroku**: The filesystem is **ephemeral** -- data is lost on dyno restart. For production use on Heroku, configure an external vector database (Pinecone, QDrant, Weaviate) and consider using the PostgreSQL image variant.

### Security
- Never commit `.env` files to version control.
- Use strong passwords when enabling `PASSWORD_PROTECT`.
- For production, put a reverse proxy (NGINX) with SSL in front of AnythingLLM.

### Token/Key Management
All API keys are stored in the `.env` file (local) or Heroku config vars (cloud). The `entrypoint.sh` script automatically bridges Heroku config vars into AnythingLLM's expected `.env` format at container boot time.
