#!/bin/bash

mkdir -p db-data
mkdir -p forms-db-data

ssh apps@fjarrkontrollen-lab.ub.gu.se "cd /apps/fjarrkontrollen-deploy && ./docker-compose-release-mailpit.sh exec db pg_dump --insert -O -x -U fjarrkontrollen_user fjarrkontrollen_db" > ./postgres-initdb.d/database,sql
echo "Backend datababase immported from lab"

ssh apps@fjarrkontrollen-lab.ub.gu.se "cd /apps/fjarrkontrollen-deploy && ./docker-compose-release-mailpit.sh exec forms_db pg_dump --insert -O -x -U fjarrkontrollen_forms_user fjarrkontrollen_forms_db" > ./forms-postgres-initdb.d/database,sql
echo "Forms backend database imported from lab"
echo "Copy secrets.env.example to secrets.env and set secret variables"

