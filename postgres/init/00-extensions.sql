-- Enable PGVector for vector similarity search (used by AnythingLLM)
CREATE EXTENSION IF NOT EXISTS vector;

-- Grant replication privileges for pg_basebackup
ALTER USER anythingllm WITH REPLICATION;

-- To add more apps, create additional databases below:
-- CREATE DATABASE myotherapp OWNER anythingllm;
-- \c myotherapp
-- CREATE EXTENSION IF NOT EXISTS vector;
