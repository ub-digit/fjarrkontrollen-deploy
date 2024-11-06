#!/bin/bash
export DOCKER_COMPOSE="docker compose"
if command -v docker-compose $> /dev/null; then
  DOCKER_COMPOSE="docker-compose"
fi
