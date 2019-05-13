# docker-run

Drone plugin that SSH into server (using SSH key) and runs a docker image.

## Usage

```
docker run --rm \
  -e PLUGIN_USERNAME=username \
  -e PLUGIN_SERVER=server.com \
  -e SSH_KEY=ssh_key \
  -e PLUGIN_LOG_DRIVER=syslog \
  -e PLUGIN_DOCKER_IMAGE=redis:latest \
  -e PLUGIN_DOCKER_NETWORK=docker_network \
  -e PLUGIN_DOCKER_NETWORK_ALIAS=network_alias \
  -e PLUGIN_CONTAINER_NAME=container_name \
  -e PLUGIN_EXPOSE=80 \
  -e PLUGIN_ENVS={"PORT": 80} \
  -e PLUGIN_MOUNTS="/some/path/on/server/:/path:ro" \
  -e SECRET_ONE=one \
  -e SECRET_TWO=two \
  cr.chuhlomin.com/docker-run
```
