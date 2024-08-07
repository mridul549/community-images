#!/bin/bash

set -x
set -e

JSON_PARAMS="$1"

JSON=$(cat "$JSON_PARAMS")

echo "Json params for docker compose coverage = $JSON"

BB_EXP_CONTAINER_NAME="blackbox-exporter"
# GRPC_CONTAINER_NAME="grpc-server"

# fetching the dynamically assigned port for blackbox-exporter using container name
BLACKBOX_EXPORTER_PORT=$(docker port "$BB_EXP_CONTAINER_NAME" 9115 | head -n 1 | awk -F: '{print $2}')

if [ -z "$BLACKBOX_EXPORTER_PORT" ]; then
  echo "Failed to retrieve the port for blackbox-exporter. Ensure the service is running."
  exit 1
fi

# Base URL of the blackbox_exporter
BASE_URL="http://localhost:${BLACKBOX_EXPORTER_PORT}"

# Targets for different probes
HTTP_TARGET="http://example.com"
TCP_TARGET="example.com:80"
ICMP_TARGET="8.8.8.8"
DNS_TARGET="8.8.8.8"
# manually hosted gRPC target
GRPC_TARGET="grpc-server:50051"

# Scrape metrics for each module
echo "Scraping HTTP probe..."
curl "${BASE_URL}/probe?target=${HTTP_TARGET}&module=http_2xx&debug=true&timeout=120s"

echo "Scraping TCP probe..."
curl "${BASE_URL}/probe?target=${TCP_TARGET}&module=tcp_connect&debug=true&ip_protocol=ip4"

echo "Scraping ICMP probe..."
curl "${BASE_URL}/probe?target=${ICMP_TARGET}&module=icmp&debug=true&ip_protocol_fallback=true"

echo "Scraping DNS probe..."
curl "${BASE_URL}/probe?target=${DNS_TARGET}&module=dns&debug=true"

echo "Scraping gRPC probe..."
curl "${BASE_URL}/probe?target=${GRPC_TARGET}&module=grpc&debug=true"

# Coverage for CLI command
docker exec -i "$BB_EXP_CONTAINER_NAME" /bin/bash -c "blackbox_exporter --help"