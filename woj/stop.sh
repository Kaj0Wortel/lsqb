#!/bin/bash

set -e
set -o pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ..

. woj/vars.sh

docker stop ${JENA_CONTAINER_NAME} || echo "No container ${JENA_CONTAINER_NAME} found"
