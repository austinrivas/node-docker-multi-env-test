#!/usr/bin/env bash

# qa
export NODE_ENV=qa
export PORT=8001
export VIRTUAL_HOST=$NODE_ENV.$BASE_SITE
export CONTAINER_NAME="${NODE_ENV}test_web_1"
export IMAGE_NAME="${NODE_ENV}test_web"
docker rm ${CONTAINER_NAME}
docker rmi ${IMAGE_NAME}


# prod
export NODE_ENV=production
export PORT=8003
export VIRTUAL_HOST=$BASE_SITE
export CONTAINER_NAME="${NODE_ENV}test_web_1"
export IMAGE_NAME="${NODE_ENV}test_web"
docker rm ${CONTAINER_NAME}
docker rmi ${IMAGE_NAME}

# nginx-proxy
docker network disconnect service-tier nginx-proxy
docker rm nginx-proxy
docker rmi jwilder/nginx-proxy

# nginx-proxy network
docker network rm service-tier

# node
docker rmi node