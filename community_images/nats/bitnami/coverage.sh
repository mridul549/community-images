#!/bin/bash

set -e
set -x

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

function test_nats() {
   local NAMESPACE=$1
   local HELM_RELEASE=$2

   NATS_USER=$(kubectl get secret --namespace "${NAMESPACE}" "${HELM_RELEASE}" -o jsonpath='{.data.*}' | base64 -d | grep -m 1 user | awk '{print $2}' | tr -d '"')
   NATS_PASS=$(kubectl get secret --namespace "${NAMESPACE}" "${HELM_RELEASE}" -o jsonpath='{.data.*}' | base64 -d | grep -m 1 password | awk '{print $2}' | tr -d '"')
   echo -e "Client credentials:\n\tUser: $NATS_USER\n\tPassword: $NATS_PASS"

   # clean up the pod with name nats-release-client first if present already
   kubectl delete pod nats-release-client --namespace "${NAMESPACE}" --ignore-not-found=true
   kubectl run nats-release-client --restart='Never' --env="NATS_USER=$NATS_USER" --env="NATS_PASS=$NATS_PASS" --image docker.io/bitnami/golang --namespace "${NAMESPACE}" --command -- sleep infinity
    # wait for nats client to come up
   kubectl wait pods nats-release-client -n "${NAMESPACE}" --for=condition=ready --timeout=10m
   echo "#!/bin/bash
   set -e
   set -x
   go env -w GOPROXY=direct
   go env -w GOSUMDB=off
   go mod init github.com/nats-io
   go get github.com/nats-io/nats.go
   cd \"\$GOPATH\"/pkg/mod/github.com/nats-io/nats.go@v1.33.1/examples/nats-pub && go get golang.org/x/crypto/blake2b@v0.14.0 && go install && cd || exit
   cd \"\$GOPATH\"/pkg/mod/github.com/nats-io/nats.go@v1.33.1/examples/nats-echo && go install && cd || exit
   timeout 10s nats-echo -s nats://$NATS_USER:$NATS_PASS@${HELM_RELEASE}.${NAMESPACE}.svc.cluster.local:4222 SomeSubject &
   nats-pub -s nats://$NATS_USER:$NATS_PASS@${HELM_RELEASE}.${NAMESPACE}.svc.cluster.local:4222 -reply Hi SomeSubject 'Hi everyone'"  > "$SCRIPTPATH"/commands.sh
   

   chmod +x "$SCRIPTPATH"/commands.sh
   POD_NAME="nats-release-client"
   kubectl -n "${NAMESPACE}" cp "${SCRIPTPATH}"/commands.sh "${POD_NAME}":/tmp/common_commands.sh

   kubectl -n "${NAMESPACE}" exec -i "${POD_NAME}" -- bash -c "/tmp/common_commands.sh"

   # delete the generated commands.sh
   rm "$SCRIPTPATH"/commands.sh
}
