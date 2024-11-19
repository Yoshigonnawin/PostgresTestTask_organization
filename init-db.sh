# init-db.sh
#!/bin/bash

# Ждем, пока база данных не станет доступной
until pg_isready -U postgres; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

echo "PostgreSQL is ready. Applying the dump..."
# Применяем дамп
psql -U postgres -d formula_bi -f /docker-entrypoint-initdb.d/dump_fbi_17_11_24.sql