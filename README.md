# node-docker-multi-env-test


Inspiration : https://staxmanade.com/2016/07/run-multiple-docker-environments--qa--beta--prod--from-the-same-docker-compose-file-/
DO Docs: https://docs.docker.com/machine/examples/ocean/#step-2-generate-a-personal-access-token

Shell access to digitalocean instance

`eval $(docker-machine env HOST_NAME)`

# Requirements:

- Support A/B Testing in Production.

- Structured Release Process.
    - Local Dev
    - CI/CD support
    - Dedicated QA/Feature Branches
    - Support Feature Flags through ENV VARS
    - Tagged Deploys and redundant production containers

- Have access to environments through various domain names.
    - my-docker-test-site.com
    - stage.my-docker-test-site.com
    - branch.my-docker-test-site.com
    
- Zero downtime deploys.

- Deploy to various environments without affecting other environments. (Ship updates to qa)

- Keep costs low. 
    - For a small site - $5/month.
    
- Use Docker as a containerization service.
    - Allows for repeatability and availability of services.
    - Leverage the open source community for infrastructure.
    
-  DigitalOcean as the cloud provider in this case
    - Pattern should be adaptable to any docker container hosting service (AWS, Google, Azure, Heroku).
    
# Example App Structure

```bash
.
|____app
| |____Dockerfile
| |____server.js
|____docker-compose.yml
```

Let's start with the ./app/* files:

# App Dockerfile

```bash
# Start from a standard nodejs image
FROM node

# Copy in the node app to the container
COPY ./server.js /app/server.js
WORKDIR /app

# Allow http connections to the server
EXPOSE 80

# Start the node server
CMD ["node", "server.js"]
```

# Start Nginx Proxy

```bash
docker run -d -p 80:80 --name nginx-proxy -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy
```

We don't have to change the port within the docker container (as shown in the Dockerfile above) but we can use the port mapping feature when starting up the docker container to specify different ports for different environments.

For example will `my-docker-test-site.com` to map to the production container, `qa.my-docker-test-site.com` the qa container of the site.

# Networking

We need to consider how the containers will be talking to each other.

We're going to create a new network and then allow the nginx-proxy to communicate via this network.

First we'll create a new network and give it a name of service-tier:

`docker network create service-tier`

Next we'll configure our nginx-proxy container to have access to this network:

`docker network connect service-tier nginx-proxy`

Now when we spin up new containers we need to be sure they are also connected to this network or the proxy will not be able to identify them as they come online, this is accomplished through the containers `docker-compose.yml`

# Define Application Containers

`docker-compose.yml`

```yaml
version: '2'

services:
  web:
    build: ./app/
    environment:
      - NODE_ENV=${NODE_ENV}
      - PORT=${PORT}
      - VIRTUAL_HOST=${VIRTUAL_HOST}
      - VIRTUAL_PORT=${PORT}
    ports:
      - "127.0.0.1:${PORT}:80"

networks:
  default:
    external:
      name: service-tier
```

- The build: ./app/ is the directory where our `Dockerfile` build is.

- The `VIRTUAL_HOST` and `VIRTUAL_PORT` are used by the `nginx-proxy` to know what port to proxy requests for and at what host/domain name.

- `VIRTUAL_HOST` feature of `nginx-proxy` to allow us to say `qa.my-docker-test-site.com`.

- We define a default network for the web app to use the `service-tier` network that we setup earlier. This allows the `nginx-proxy` and our running instances of the web container to correctly talk to each other.


# Local Hosts File

Set the entries in your local hosts file to reflect the IP of your local dev container.

```bash
127.0.0.1 qa.my-docker-test-site.com
127.0.0.1 my-docker-test-site.com
```

# Testing Local Environment

If everything is working properly on your local machine you should be able to visit `my-docker-test-site.com` & `qa.my-docker-test-site.com` and see:

```html
Hello World!

VIRTUAL_HOST: qa.my-docker-test-site.com
NODE_ENV: qa
PORT: 8001
```

# Deploying

## Create a Docker Droplet

We're going to use a cool feature of `docker-machine` where we can leverage the DigitalOcean driver to help us create and manage our docker images.

* Complete `Step 1` and `Step 2` in the following post [DigitalOcean example](https://docs.docker.com/machine/examples/ocean/) to acquire a DigitalOcean personal access token.
 
* Use the Digital Ocean Access Token to create an image
 
    ```bash
    DOTOKEN=XXXX
    DIGITALOCEAN_IMAGE="ubuntu-16-04-x64"
    docker-machine create --driver digitalocean --digitalocean-access-token $DOTOKEN docker-multi-environment
    ```
    
* Configure local terminal to pipe input into your newly created DO image

    ```bash
    eval $(docker-machine env docker-multi-environment)
    ```
    
* Test connection by running `docker ps`. You should see the image you just created running on DO, you can verify this by visiting the DO droplets page for your account.

* Spin up our remote nginx-proxy on the remote droplet
  
    ```bash
    docker run -d -p 80:80 --name nginx-proxy -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy
    ```
  
* Create `service-tier` network and connect it to `nginx-proxy`

    ```bash
    docker network create service-tier
    docker network connect service-tier nginx-proxy
    ```
    
* Configure DNS
    - [How To Set Up a Host Name with DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-host-name-with-digitalocean)
    - [How To Set Up and Test DNS Subdomains with DigitalOcean's DNS Panel](https://www.digitalocean.com/community/tutorials/how-to-set-up-and-test-dns-subdomains-with-digitalocean-s-dns-panel)
    
* Run deploy script, this is an example script that will be hardened for production apps.

    ```bash
    BASE_SITE=my-docker-test-site.com
    
    # qa
    export NODE_ENV=qa
    export PORT=8001
    export VIRTUAL_HOST=$NODE_ENV.$BASE_SITE
    docker-compose -p ${VIRTUAL_HOST} up -d
    
    
    # prod
    export NODE_ENV=production
    export PORT=8003
    export VIRTUAL_HOST=$BASE_SITE
    docker-compose -p ${VIRTUAL_HOST} up -d
    ```
    
## Deploying changes with no downtime

Deployments consist of building a container and setting the `VIRTUAL_HOST` entry to point to the environemt you are deploying to.

An example configuration that would deploy to QA would look like:

```bash
BASE_SITE=my-docker-test-site.com

export NODE_ENV=qa
export PORT=8004
export VIRTUAL_HOST=$NODE_ENV.$BASE_SITE
docker-compose -p ${VIRTUAL_HOST}x2 up -d
```

Note the `x2` in the `docker-compose` name property.

When you `docker ps` you should see 4 containers running 1 `nginx-proxy` container, 1 `prod` container, 2 `qa` containers.

One of the advantages of this approach is if there was something seriously wrong with the new `qa` release you could just stop the new container `docker stop <new_container_id>` and the proxy will start redirecting back to the old `qa` container.

Removing an old container involves stopping the container and removing the image.

```bash
docker ps # to list the containers running
docker stop <old_qa_container_id>

docker images # to list the images we have on our instance
docker rmi <old_qa_image_id>
```

## Destroying an DO Droplet

The following command will completely remove the droplet from DigitalOcean.

`docker-machine rm docker-multi-environment`

# TODO

* Deployment Automation
* CI/CD Integration
* Database Containers and Migrations
* SSL (consider cloudflare or letsencrypt?)
* Easy way to secure the qa/stage environments?