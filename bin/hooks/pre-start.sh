#!/usr/bin/env bash
if [ "${APP_MIGRATE}" == "true" ]; then
  echo "[WARNING] Migrating database!"
  ./bin/${APPLICATION_NAME} migrate
fi;
