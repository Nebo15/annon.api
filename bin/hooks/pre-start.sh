#!/bin/sh
# `pwd` should be /opt/gateway
APP_NAME="gateway"

if [ "${APP_MIGRATE}" == "true" ]; then
  echo "[WARNING] Migrating database!"
  ./bin/$APP_NAME command "os_gateway_tasks" migrate!
fi;