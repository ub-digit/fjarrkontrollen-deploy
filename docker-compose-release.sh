#!/bin/bash
docker compose -f docker-compose.yml -f docker-compose.release.yml -f docker-compose.release.logging.yml $@
