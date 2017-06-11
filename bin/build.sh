#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${DIR}/ci/release/fetch-project-environment.sh
${DIR}/ci/release/build-container.sh $@
