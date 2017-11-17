#!/usr/bin/env bash

BASE_SITE=my-docker-test-site.com

# qa
export NODE_ENV=qa
export PORT=8001
export VIRTUAL_HOST=$NODE_ENV.$BASE_SITE
export CONTAINER_NAME="${NODE_ENV}test_web_1"
docker network disconnect service-tier ${CONTAINER_NAME}
docker stop ${CONTAINER_NAME}


# prod
export NODE_ENV=production
export PORT=8003
export VIRTUAL_HOST=$BASE_SITE
export CONTAINER_NAME="${NODE_ENV}test_web_1"
docker network disconnect service-tier ${CONTAINER_NAME}
docker stop ${CONTAINER_NAME}

# nginx-proxy
docker stop nginx-proxy