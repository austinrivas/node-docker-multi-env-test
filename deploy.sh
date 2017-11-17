#!/usr/bin/env bash

DOTOKEN=6457ffa0c3346c86c6072c295f18e452911bbea513dbc652bebdb227ed81c59e
DIGITALOCEAN_IMAGE="ubuntu-16-04-x64"

docker-machine create --driver digitalocean --digitalocean-access-token $DOTOKEN docker-multi-environment