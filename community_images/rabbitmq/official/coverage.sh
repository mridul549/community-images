#!/bin/bash

set -e
set -x

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

function test_rabbitmq() {
    local NAMESPACE=$1
    local RABBITMQ_SERVER=$2
    local RABBITMQ_PASS=$3

    PUBLISHER_NAME="publisher"
    docker run --name "${PUBLISHER_NAME}" \
           --network "${NAMESPACE}"_default \
           bitnami/python \
           sleep infinity
    
    # wait for publisher pod to come up
    sleep 30
    echo "#!/bin/bash
    pip install pika
    python3 /tmp/publish.py --rabbitmq-server=$RABBITMQ_SERVER --password=$RABBITMQ_PASS" > "$SCRIPTPATH"/publish_commands.sh

    docker cp "${SCRIPTPATH}"/publish.py "${PUBLISHER_NAME}":/tmp/publish.py
    chmod +x "$SCRIPTPATH"/publish_commands.sh
    docker cp "${SCRIPTPATH}"/publish_commands.sh "${PUBLISHER_NAME}":/tmp/publish_commands.sh

    docker exec -i "${PUBLISHER_NAME}" -- bash -c "/tmp/publish_commands.sh"

    # consumer specific
    CONSUMER_NAME="consumer"
    docker run --name "${CONSUMER_NAME}" --image bitnami/python --network "${NAMESPACE}"_default --command -- sleep infinity
    # wait for consumer pod to come up
    sleep 30
    echo "#!/bin/bash
    pip install pika
    python3 /tmp/consume.py --rabbitmq-server=$RABBITMQ_SERVER --password=$RABBITMQ_PASS" > "$SCRIPTPATH"/consume_commands.sh

    docker cp "${SCRIPTPATH}"/consume.py "${CONSUMER_NAME}":/tmp/consume.py
    chmod +x "$SCRIPTPATH"/consume_commands.sh
    docker cp "${SCRIPTPATH}"/consume_commands.sh "${CONSUMER_NAME}":/tmp/consume_commands.sh

    docker exec -i "${CONSUMER_NAME}" -- bash -c "/tmp/consume_commands.sh"

    # delete the client containers
    docker stop "${PUBLISHER_NAME}"
    docker stop "${CONSUMER_NAME}"
    docker rm "${PUBLISHER_NAME}"
    docker rm "${CONSUMER_NAME}"

    # delete the generated command files
    rm "$SCRIPTPATH"/publish_commands.sh
    rm "$SCRIPTPATH"/consume_commands.sh

    PERF_POD="perf-test"
    DEFAULT_RABBITMQ_USER='user'
    PERF_TEST_IMAGE_VERSION='2.18.0'

    # run the perf benchmark test
    docker run -it --name "${PERF_POD}"\
        --env RABBITMQ_PERF_TEST_LOGGERS=com.rabbitmq.perf=debug,com.rabbitmq.perf.Producer=debug \
        --env DEFAULT_RABBITMQ_USER="${DEFAULT_RABBITMQ_USER}" \
        --env RABBITMQ_PASS="${RABBITMQ_PASS}" \
        --env RABBITMQ_SERVER="${RABBITMQ_SERVER}" \
        pivotalrabbitmq/perf-test:"${PERF_TEST_IMAGE_VERSION}" \
        --uri amqp://"${DEFAULT_RABBITMQ_USER}":"${RABBITMQ_PASS}"@"${RABBITMQ_SERVER}" \
        --time 10

    # check for message from perf test
    out=$(docker logs "${PERF_POD}" | grep -ic 'consumer latency')

    if (( out < 1 )); then
        echo "The perf benchmark didn't run properly"
        return 1
    fi

    # delete the perf container
    docker stop "${PERF_POD}"
    docker rm "${PERF_POD}"
}
