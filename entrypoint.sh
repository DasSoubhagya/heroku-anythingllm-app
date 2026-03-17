#!/bin/bash
set -e

STORAGE_DIR="${STORAGE_DIR:-/app/server/storage}"
ENV_FILE="/app/server/.env"

mkdir -p "$STORAGE_DIR"

# Write environment variables to .env file for AnythingLLM to read
# This bridges Heroku config vars into AnythingLLM's expected .env format
echo "STORAGE_DIR=${STORAGE_DIR}" > "$ENV_FILE"

ENV_VARS=(
  AUTH_TOKEN JWT_SECRET
  OPENROUTER_API_KEY OPENROUTER_MODEL_PREF
  GENERIC_OPEN_AI_BASE_PATH GENERIC_OPEN_AI_KEY
  GENERIC_OPEN_AI_MODEL_PREF GENERIC_OPEN_AI_MAX_TOKENS
  EMBEDDING_ENGINE EMBEDDING_MODEL_PREF
  VECTOR_DB
  CHROMA_ENDPOINT
  PINECONE_API_KEY PINECONE_INDEX
  QDRANT_ENDPOINT
  WEAVIATE_ENDPOINT
  MILVUS_ADDRESS
  WHISPER_PROVIDER
  DISABLE_TELEMETRY
  PASSWORD_PROTECT SINGLE_USER_PASSWORD
  MULTI_USER_MODE
)

for var in "${ENV_VARS[@]}"; do
  val="${!var}"
  if [ -n "$val" ]; then
    echo "${var}=${val}" >> "$ENV_FILE"
  fi
done

# Heroku provides $PORT; AnythingLLM listens on 3001 by default.
# Use socat to forward Heroku's $PORT to 3001 if PORT != 3001
if [ -n "$PORT" ] && [ "$PORT" != "3001" ]; then
  socat TCP-LISTEN:${PORT},fork TCP:127.0.0.1:3001 &
fi

cd /app/server
exec node index.js
