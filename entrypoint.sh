#!/bin/bash
set -e

function error {
    echo "Error; $1"
}

RUNNER_OPTIONS=""
SCOPE=""
RUNNERTOKEN=""

if [[ -z $RUNNER_NAME ]]; then
    echo "Using hostname for Actions Runner Name."
    export RUNNER_NAME=${HOSTNAME}
fi

# We need to know what type of runner we are
if [[ -z "${RUNNER_ENTERPRISE_URL}" && -z "${RUNNER_ORGANIZATION_URL}" && -z "${RUNNER_REPOSITORY_URL}" ]]; then
    error "RUNNER_ENTERPRISE_URL, RUNNER_ORGANIZATION_URL or RUNNER_REPOSITORY_URL needs to be specified when registering an Actions runner"
    exit 1
fi

# Use priority of enterprise -> organization -> repoistory if more than one specified
if [[ -n ${RUNNER_ENTERPRISE_URL} ]]; then
    export RUNNER_URL=${RUNNER_ENTERPRISE_URL}
    SCOPE=enterprises
elif [[ -n ${RUNNER_ORGANIZATION_URL} ]]; then
    export RUNNER_URL=${RUNNER_ORGANIZATION_URL}
    SCOPE=orgs
elif [[ -n ${RUNNER_REPOSITORY_URL} ]]; then
    export RUNNER_URL=${RUNNER_REPOSITORY_URL}
    SCOPE=repos
fi

# If the user has provided any runner labels add them to the config options
if [[ -n ${RUNNER_LABELS} ]]; then
    RUNNER_OPTIONS="${RUNNER_OPTIONS} --labels ${RUNNER_LABELS}"
fi

# The runner group that the self-hosted runner will be registered with
GROUP=${RUNNER_GROUP:-"default"}

#echo "Getting temporary access token for registering"
#getRegistrationToken

echo "Configuring GitHub Actions Runner and registering"
./config.sh --unattended \
    --url "${RUNNER_URL}" \
    --token "${RUNNERTOKEN}" \
    --name "${RUNNER_NAME}" \
    --work ${RUNNER_WORK_DIRECTORY} \
    --runnergroup ${GROUP} \
    $RUNNER_OPTIONS

echo "Starting GitHub Actions Runner"
env -i ./runsvc.sh

# Deregister
#echo Cleaning up runner registration...
#getRegistrationToken
#./config.sh remove --token "${TOKEN}"
