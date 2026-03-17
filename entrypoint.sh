#!/bin/bash
set -e

STORAGE_DIR="${STORAGE_DIR:-/app/server/storage}"
ENV_FILE="/app/server/.env"

mkdir -p "$STORAGE_DIR"

echo "STORAGE_DIR=${STORAGE_DIR}" > "$ENV_FILE"

ENV_VARS=(
  AUTH_TOKEN JWT_SECRET
  DATABASE_URL
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

# Heroku provides $PORT; AnythingLLM listens on 3001.
# Use Node.js (already available) to proxy Heroku's port to 3001.
if [ -n "$PORT" ] && [ "$PORT" != "3001" ]; then
  node -e "
    const net = require('net');
    net.createServer(c => {
      const s = net.connect(3001, '127.0.0.1');
      c.pipe(s); s.pipe(c);
      c.on('error', () => s.destroy());
      s.on('error', () => c.destroy());
    }).listen(${PORT}, () => console.log('Port proxy: ${PORT} -> 3001'));
  " &
fi

cd /app/server
npx prisma generate --schema=./prisma/schema.prisma 2>/dev/null || true
npx prisma migrate deploy --schema=./prisma/schema.prisma 2>/dev/null || true
exec node index.js
