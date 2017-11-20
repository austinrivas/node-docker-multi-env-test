#!/usr/bin/env bash
BASE_SITE=my-docker-test-site.com

export NODE_ENV=qa
export PORT=8009
export CONTAINER_NAME="${NODE_ENV}test"
export VIRTUAL_HOST="lwrc-123.${BASE_SITE}"
docker-compose -p ${CONTAINER_NAME}x3 up -d