#/bin/sh

set -e

ENVS=""
for env in $(echo ${PLUGIN_ENVS} | jq -r '. | to_entries[] | "\(.key)=\"\(.value)\""')
do
    ENVS="${ENVS} --env ${env}"
done

SECRETS_MASK=""
SECRET_ENVS=""
for env in $(printenv | grep "SECRET_")
do
    if [[ ${env:0:7} == "SECRET_" ]] # len("SECRET_") = 7
    then
        pair=${env:7}
        SECRET_ENVS="${SECRET_ENVS} --env ${pair%%=*}=\"${pair#*=}\""
        SECRETS_MASK="${SECRET_ENVS} --env ${pair%%=*}=\"*REDUCTED*\""
    fi
done

VOLUMES=""
for mount in $(echo ${PLUGIN_MOUNTS} | tr "," "\n")
do
    VOLUMES="${VOLUMES} --volume ${mount}"
done

LOG_DRIVER=""
if [ ! -z $PLUGIN_LOG_DRIVER ];
then
    LOG_DRIVER="--log-driver ${PLUGIN_LOG_DRIVER}"
fi

LOG_OPT=""
for opt in $(echo ${PLUGIN_LOG_OPT} | jq -r '. | to_entries[] | "\(.key)=\"\(.value)\""')
do
    LOG_OPT="${LOG_OPT} --log-opt ${opt}"
done

if [ -z "$PLUGIN_EXPOSE" ]; then EXPOSE=""; else EXPOSE="--expose ${PLUGIN_EXPOSE}"; fi
if [ -z "$PLUGIN_RESTART" ]; then RESTART=""; else RESTART="--restart ${PLUGIN_RESTART}"; fi

PORTS=""
for p in $(echo ${PLUGIN_PORTS} | tr "," "\n")
do
    PORTS="${PORTS} -p ${p}"
done

RM="--rm"
if [ ! -z "$RESTART" ];
then
    RM="" # otherwise getting error: Conflicting options: --restart and --rm.
fi

echo "${SSH_KEY}" > /key
chmod 600 /key

if [ -z $PLUGIN_CONTAINER_NAME ] && [ ! -z $PLUGIN_DOCKER_NETWORK ];
then
    PLUGIN_CONTAINER_NAME="$PLUGIN_DOCKER_NETWORK_ALIAS"
fi

NETWORK_ALIAS=""
if [ ! -z $PLUGIN_DOCKER_NETWORK_ALIAS ];
then
    NETWORK_ALIAS="--network-alias ${PLUGIN_DOCKER_NETWORK_ALIAS}"
fi

NETWORK=""
if [ ! -z $PLUGIN_DOCKER_NETWORK ];
then
    NETWORK="--network ${PLUGIN_DOCKER_NETWORK}"
fi

SUDO=""
if [[ "$PLUGIN_SUDO" == "true" ]];
then
    SUDO="sudo"
fi

if [[ "$PLUGIN_DEBUG" == "true" ]];
    echo "Labels from plugin: ${PLUGIN_LABELS}"
fi

LABELS=""
for label in $(echo ${PLUGIN_LABELS} | jq -r '. | to_entries[] | "\(.key)=\"\(.value)\""')
do
    LABELS="${LABELS} --label ${label}"

    if [[ "$PLUGIN_DEBUG" == "true" ]];
        echo "Lables: $LABELS"
    fi
done

if [[ "$PLUGIN_DEBUG" == "true" ]];
then
    echo "docker run --detach --name $PLUGIN_CONTAINER_NAME \
        $RM $RESTART $EXPOSE $PORTS $ENVS $SECRETS_MASK $VOLUMES \
        $NETWORK $NETWORK_ALIAS \
        $LOG_DRIVER $LOG_OPT \
        $LABELS \
        $PLUGIN_DOCKER_IMAGE $PLUGIN_COMMAND"
fi

ssh -o "StrictHostKeyChecking=no" ${PLUGIN_USERNAME}@${PLUGIN_SERVER} -i /key "${SUDO} docker pull ${PLUGIN_DOCKER_IMAGE} && \
    ${SUDO} docker stop $PLUGIN_CONTAINER_NAME || true && \
    ${SUDO} docker wait $PLUGIN_CONTAINER_NAME || true && \
    ${SUDO} docker rm $PLUGIN_CONTAINER_NAME || true && \
    ${SUDO} docker run --detach --name $PLUGIN_CONTAINER_NAME \
        $RM $RESTART $EXPOSE $PORTS $ENVS $SECRET_ENVS $VOLUMES \
        $NETWORK $NETWORK_ALIAS \
        $LOG_DRIVER $LOG_OPT \
        $LABELS \
        $PLUGIN_DOCKER_IMAGE $PLUGIN_COMMAND"
