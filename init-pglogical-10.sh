#!/bin/bash
set -e

# Aguarda até que o PostgreSQL esteja pronto para aceitar comandos
until pg_isready; do
  echo "Aguardando o PostgreSQL ficar pronto..."
  sleep 1
done

# Executa comandos como o usuário postgres
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Ativa a extensão pg_logical
    CREATE EXTENSION IF NOT EXISTS pg_logical;

EOSQL
# -- Exemplo de como criar um nó de replicação. Ajuste conforme necessário
# SELECT pg_logical.create_node(
#     node_name := 'provider',
#     dsn := 'host=provider_host port=5432 dbname=mydb'
# );
