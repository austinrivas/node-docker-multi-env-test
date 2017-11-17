#!/usr/bin/env bash

BASE_SITE=my-docker-test-site.local

# network
docker network create service-tier

# nginx-proxy
docker run -d -p 80:80 --name nginx-proxy -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy
docker network connect service-tier nginx-proxy

# qa
export NODE_ENV=qa
export PORT=8001
export VIRTUAL_HOST=$NODE_ENV.$BASE_SITE
export CONTAINER_NAME="${NODE_ENV}test"
docker-compose -p ${CONTAINER_NAME} up -d


# prod
export NODE_ENV=production
export PORT=8003
export VIRTUAL_HOST=$BASE_SITE
export CONTAINER_NAME="${NODE_ENV}test"
docker-compose -p ${CONTAINER_NAME} up -d