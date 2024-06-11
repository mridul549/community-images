#!/bin/bash

set -x
set -e

JSON_PARAMS="$1"

JSON=$(cat "$JSON_PARAMS")

echo "Json params for docker compose coverage = $JSON"
NAMESPACE=$(jq -r '.namespace_name' < "$JSON_PARAMS")
NAMESPACE=$(jq -r '.namespace_name' < "$JSON_PARAMS")

CONTAINER_NAME="${NAMESPACE}"-pgpool-1
NETWORK_NAME="${NAMESPACE}"-default

#setup postgres client and connecting it to pgpool

docker run --rm --network="${NETWORK_NAME}" -e POSTGRESQL_PASSWORD=adminpassword  bitnami/postgresql:11






