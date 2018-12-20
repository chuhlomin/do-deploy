#/bin/sh

set -e

ENVS=""
for env in $(echo $PLUGIN_ENVS | jq '. | to_entries[] | "\(.key)=\"\(.value)\""')
do
    ENVS="${ENVS} --env ${env}"
done

SECRET_ENVS=""
for env in $(printenv | grep "SECRET_")
do
    if [[ $env == SECRET_* ]]
    then
        SECRET_ENVS="${SECRET_ENVS} --env ${env:7}" # len("SECRET_") = 7
    fi
done

VOLUMES=""
for mount in $(echo $PLUGIN_MOUNTS | tr "," "\n")
do
    VOLUMES="${VOLUMES} --volume ${mount}"
done

echo "$SSH_KEY" > /key
chmod 600 /key

ssh -o "StrictHostKeyChecking=no" ${PLUGIN_USERNAME}@${PLUGIN_SERVER} -i /key "docker pull ${PLUGIN_DOCKER_IMAGE} && \
    echo \"--name ${PLUGIN_CONTAINER_NAME} \
        $ENVS $SECRET_ENVS \
        $VOLUMES \
        --expose ${PLUGIN_EXPOSE} \
        --network ${PLUGIN_DOCKER_NETWORK} \
        --network-alias=${PLUGIN_DOCKER_NETWORK_ALIAS} \
        ${PLUGIN_DOCKER_IMAGE}\" > command.txt"

# docker stop ${PLUGIN_CONTAINER_NAME} && \
# docker wait ${PLUGIN_CONTAINER_NAME} && \
# docker run --rm -d --name ${PLUGIN_CONTAINER_NAME} \