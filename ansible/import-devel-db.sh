#!/bin/bash

# Exit on error
set -e 

if [[ -z "$1" ]]; then
    echo "Usage: $0 <target>"
    echo "<target> must be on of staging, lab or production"
    exit 0;
fi

targets="staging lab production"
target=$1

if [[ ! " $targets " =~ " $target " ]]; then
    echo "<target> must be on of staging, lab, prod or production"
    exit 1;
fi

#./run-playbook.sh $1 export-db
cd ..

RUNNING=$(docker compose ps db -q)
if [[ -z "$RUNNING" ]]; then
  echo "The service 'db' is down, run docker compose up -d db in docker directory"
  exit 1;
fi
docker compose exec db bash -c 'psql -d postgres -U $POSTGRES_USER -c "DROP DATABASE IF EXISTS $POSTGRES_DB;"'
docker compose exec db bash -c 'psql -d postgres -U $POSTGRES_USER -c "CREATE DATABASE $POSTGRES_DB;"'
docker compose exec -T db bash -c 'psql -d $POSTGRES_DB $POSTGRES_USER' < ./ansible/data/database.sql

RUNNING=$(docker compose ps forms_db -q)
if [[ -z "$RUNNING" ]]; then
  echo "The service 'forms_db' is down, run docker compose up -d forms_db in docker directory"
  exit 1;
fi

docker compose exec forms_db bash -c 'psql -d postgres -U $POSTGRES_USER -c "DROP DATABASE IF EXISTS $POSTGRES_DB;"'
docker compose exec forms_db bash -c 'psql -d postgres -U $POSTGRES_USER -c "CREATE DATABASE $POSTGRES_DB;"'
docker compose exec -T forms_db bash -c 'psql -d $POSTGRES_DB $POSTGRES_USER' < ./ansible/data/forms-database.sql

echo "Databases has been imported"
