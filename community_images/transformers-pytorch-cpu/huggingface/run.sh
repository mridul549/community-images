#!/bin/bash

set -x

. ../../common/helpers.sh


TAG=$1
INPUT_REGISTRY=docker.io
INPUT_ACCOUNT=huggingface
REPOSITORY=transformers-pytorch-cpu

test()
{
    local IMAGE_REPOSITORY=$1
    echo "Testing hugging face transformers-pytorch-cpu"
    docker run -it --rm=true --name transformers-pytorch-cpu-${TAG} --cap-add=SYS_PTRACE -v "$(pwd)"/src:/app --workdir=/app ${IMAGE_REPOSITORY}:${TAG} python3 sample.py
    # sleep for 30 min
    echo "waiting for 30 sec"
    sleep 30s
}

build_images ${INPUT_REGISTRY} ${INPUT_ACCOUNT} ${REPOSITORY} ${TAG} test
