#!/bin/bash

set -x
set -e

JSON_PARAMS="$1"

JSON=$(cat "$JSON_PARAMS")

echo "Json params for k8s coverage = $JSON"

NAMESPACE=$(jq -r '.namespace_name' < "$JSON_PARAMS")
RELEASE_NAME=$(jq -r '.release_name' < "$JSON_PARAMS")

# current scriptpath
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Apply the manifest file to create resources for all elastic applications supported by eck-operator
kubectl apply -f "${SCRIPTPATH}"/manifests/manifest.yml

# Wait until all pods are in the Running or Completed state
echo "Waiting for all pods in namespace "$NAMESPACE" to be running..."

while true; do
  pending_pods=$(kubectl get pods -n "$NAMESPACE" --no-headers | awk '{print $3}' | grep -vE 'Running|Completed' | wc -l)
  if [ "$pending_pods" -eq 0 ]; then
    echo "All pods are now running in namespace "$NAMESPACE"."
    break
  else
    sleep 5
  fi
done

# Calling the coverage scripts one by one
""${SCRIPTPATH}"/coverage/elasticsearch.sh" "${NAMESPACE}"

# Cleanup
kubectl delete -f "${SCRIPTPATH}"/manifests/manifest.yml