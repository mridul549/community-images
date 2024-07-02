#!/bin/bash

set -x
set -e

JSON_PARAMS="$1"

JSON=$(cat "$JSON_PARAMS")

echo "Json params for docker compose coverage = $JSON"

PROJECT_NAME=$(jq -r '.project_name' < "$JSON_PARAMS")
CONTAINER_NAME=${PROJECT_NAME}-elastic-agent-1

sleep 20

curl -XGET 'http://localhost:9200/_cat/indices?v&pretty'

docker exec "${CONTAINER_NAME}" /bin/bash /tmp/test_commands.sh