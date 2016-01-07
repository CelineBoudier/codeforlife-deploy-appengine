#!/bin/bash -ex

${SNAP_CACHE_DIR}

export CLOUDSDK_CORE_DISABLE_PROMPTS=1
export CLOUDSDK_PYTHON_SITEPACKAGES=1
if [ ! -d ${SNAP_CACHE_DIR}/google-cloud-sdk ]; then
    wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-91.0.1-linux-x86_64.tar.gz
    tar zxf google-cloud-sdk-91.0.1-linux-x86_64.tar.gz -C ${SNAP_CACHE_DIR}
    rm google-cloud-sdk-91.0.1-linux-x86_64.tar.gz
fi

GCLOUD=${SNAP_CACHE_DIR}/google-cloud-sdk/bin/gcloud

${GCLOUD} --quiet components update
${GCLOUD} auth activate-service-account --key-file .gcloud-key

export MODULE_NAME=$1
export DATABASE_NAME="cfl_${MODULE_NAME}"
export CACHE_PREFIX="${MODULE_NAME}-"
export VERSION="$2"

./manage.py migrate --noinput -v 2

envsubst <app.yaml.tmpl >app.yaml

${GCLOUD} preview app --quiet --verbosity info deploy app.yaml --project ${APP_ID} --version ${VERSION}

# Test the site
./test.sh ${MODULE_NAME} ${VERSION}

# Promote
${GCLOUD} preview app modules set-default --project ${APP_ID} --version ${VERSION} ${MODULE_NAME}
