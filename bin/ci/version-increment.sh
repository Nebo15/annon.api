#!/bin/bash

# This script increments patch version number in mix.exs according to a SEMVER spec.

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

# Increment patch version
# Source: https://github.com/fmahnke/shell-semver/blob/master/increment_version.sh
a=( ${PROJECT_VERSION//./ } )
((a[2]++))
NEW_PROJECT_VERSION="${a[0]}.${a[1]}.${a[2]}"

echo "[I] Incrementing project version from '${PROJECT_VERSION}' to '${NEW_PROJECT_VERSION}' in 'mix.exs'."
sed -i'' -e "s/@version \"${PROJECT_VERSION}\"/@version \"${NEW_PROJECT_VERSION}\"/g" "${PROJECT_DIR}/mix.exs"

# Here you can modify other files (for eg. README.md) that contains version.
