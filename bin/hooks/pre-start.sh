#!/bin/sh
# `pwd` should be /opt/annon_api
APP_NAME="annon_api"

if [ "${APP_MIGRATE}" == "true" ]; then
  echo "[WARNING] Migrating database!"
  ./bin/$APP_NAME command "annon_api_tasks" migrate!
fi;
