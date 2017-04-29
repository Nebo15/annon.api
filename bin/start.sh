#!/bin/bash
# This script starts a local Docker container with created image.

# Find mix.exs inside project tree.
# This allows to call bash scripts within any folder inside project.
PROJECT_DIR=$(git rev-parse --show-toplevel)
if [ ! -f "${PROJECT_DIR}/mix.exs" ]; then
    echo "[E] Can't find '${PROJECT_DIR}/mix.exs'."
    echo "    Check that you run this script inside git repo or init a new one in project root."
fi

# Extract project name and version from mix.exs
PROJECT_NAME=$(sed -n 's/.*app: :\([^, ]*\).*/\1/pg' "${PROJECT_DIR}/mix.exs")
PROJECT_VERSION=$(sed -n 's/.*@version "\([^"]*\)".*/\1/pg' "${PROJECT_DIR}/mix.exs")
HOST_IP=`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | head -n 1`
HOST_NAME="travis"

echo "[I] Starting a Docker container '${PROJECT_NAME}' (version '${PROJECT_VERSION}') from path '${PROJECT_DIR}'.."
echo "[I] Assigning parent host '${HOST_NAME}' with IP '${HOST_IP}'."

# Allow to pass -i option to start container in interactive mode
OPTS="-d"
while getopts "i" opt; do
  case "$opt" in
    i)  OPTS="-it --rm"
        ;;
  esac
done

docker run -p 4000:4000 \
       --env-file .env \
       ${OPTS} \
       --add-host=$HOST_NAME:$HOST_IP \
       --name ${PROJECT_NAME} \
       "${PROJECT_NAME}:${PROJECT_VERSION}"

