#!/usr/bin/env bash
BASE_SITE=my-docker-test-site.com

export NODE_ENV=production
export PORT=8002
export CONTAINER_NAME="${NODE_ENV}test"
export VIRTUAL_HOST=$BASE_SITE
docker-compose -p ${CONTAINER_NAME}x3 up -d