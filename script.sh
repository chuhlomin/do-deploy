#/bin/sh

set -e

ENVS=""
for env in $(echo ${PLUGIN_ENVS} | jq -r '. | to_entries[] | "\(.key)=\"\(.value)\""')
do
    ENVS="${ENVS} --env ${env}"
done

SECRET_ENVS=""
for env in $(printenv | grep "SECRET_")
do
    if [[ ${env:0:7} == "SECRET_" ]] # len("SECRET_") = 7
    then
        pair=${env:7}
        SECRET_ENVS="${SECRET_ENVS} --env ${pair%%=*}=\"${pair#*=}\""
    fi
done

VOLUMES=""
for mount in $(echo ${PLUGIN_MOUNTS} | tr "," "\n")
do
    VOLUMES="${VOLUMES} --volume ${mount}"
done

if [ -z "$PLUGIN_EXPOSE" ]; then EXPOSE=""; else EXPOSE="--expose ${PLUGIN_EXPOSE}"; fi
if [ -z "$PLUGIN_RESTART" ]; then RESTART=""; else RESTART="--restart ${RESTART}"; fi

echo "${SSH_KEY}" > /key
chmod 600 /key

ssh -o "StrictHostKeyChecking=no" ${PLUGIN_USERNAME}@${PLUGIN_SERVER} -i /key "docker pull ${PLUGIN_DOCKER_IMAGE} && \
    docker stop ${PLUGIN_CONTAINER_NAME} || true && \
    docker wait ${PLUGIN_CONTAINER_NAME} || true && \
    docker rm ${PLUGIN_CONTAINER_NAME} || true && \
    docker run --rm --detach --name ${PLUGIN_CONTAINER_NAME} \
        $RESTART $EXPOSE $ENVS $SECRET_ENVS $VOLUMES \
        --network ${PLUGIN_DOCKER_NETWORK} \
        --network-alias ${PLUGIN_DOCKER_NETWORK_ALIAS} \
        --log-driver ${PLUGIN_LOG_DRIVER} \
        ${PLUGIN_DOCKER_IMAGE}"
