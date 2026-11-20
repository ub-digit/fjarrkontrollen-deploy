#!/bin/bash
set -ex

APP_PATH=${APP_PATH:-/home/node/app}
APP_TEMP_PATH=${APP_TEMP_PATH:-"$APP_PATH/tmp"}
APP_SETUP_LOCK=${APP_SETUP_LOCK:-"$APP_TEMP_PATH/setup.lock"}
APP_SETUP_WAIT=${APP_SETUP_WAIT:-5}

if [ "$#" -eq 0 ]; then
  set -- ember server --environment="${EMBER_ENVIRONMENT:-}" --live-reload-port "${EMBER_LIVE_RELOAD_PORT:-35730}"
fi

if [ "$1" = ember ]; then
  while [ -f "$APP_SETUP_LOCK" ]; do
    echo "Waiting for app setup to finish..."
    sleep "$APP_SETUP_WAIT"
  done

  mkdir -p "$APP_TEMP_PATH"
  touch "$APP_SETUP_LOCK"
  trap 'rm -f "$APP_SETUP_LOCK"' EXIT

  if ! check-dependencies; then
    npm install
  fi
  if [ -f bower.json ]; then
    bower install
  fi

  rm -f "$APP_SETUP_LOCK"
fi

exec "$@"
