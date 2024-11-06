#!/bin/bash

if [[ -z "$1" || !("$1" == "lab" || "$1" == "staging" || "$1" == "production") ]]; then
  echo "Usage $0 <staging-environemnt>"
  echo "<staging-environment> used for fetching database data must be set to either 'lab' 'staging' or 'production'"
  exit
fi

SSH_HOST="fjarrkontrollen.ub.gu.se"
if [[ "$1" != "production" ]]; then
  SSH_HOST="fjarrkontrollen-$1.ub.gu.se"
fi

REPO_DIR="/apps"
if [[ "$1" == "staging" ]]; then
  REPO_DIR="/home/apps"
fi

mkdir -p db-data
mkdir -p forms-db-data

ssh apps@$SSH_HOST "cd $REPO_DIR/fjarrkontrollen-deploy && ./docker-compose-release-mailpit.sh exec db pg_dump --insert -O -x -U fjarrkontrollen_user fjarrkontrollen_db" > ./postgres-initdb.d/database,sql
echo "Backend datababase immported from lab"

ssh apps@$SSH_HOST "cd $REPO_DIR/fjarrkontrollen-deploy && ./docker-compose-release-mailpit.sh exec forms_db pg_dump --insert -O -x -U fjarrkontrollen_forms_user fjarrkontrollen_forms_db" > ./forms-postgres-initdb.d/database,sql

echo "Forms backend database imported from $1"
echo "Copy secrets.env.example to secrets.env and set secret variables"

