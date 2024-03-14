#!/bin/bash

# Basic "rsync" test
# It doesn't use federated credentials, but it uses a SAS token to access the storage account,
# to make sure the container is accessible.

# Usage:
# ./rsync.sh <STORAGE_ACCOUNT> <RESOURCE_GROUP> <CONTAINER_NAME>

STORAGE_ACCOUNT=$1
RESOURCE_GROUP=$2
CONTAINER_NAME=$3

TEST_RUN_DATE=`date +%Y-%-m-%d'T'%H:%M:%SZ`

ACCOUNT_KEY=`az storage account keys list --account-name ${STORAGE_ACCOUNT} --resource-group ${RESOURCE_GROUP} --query '[0].value' -o tsv`
echo "Getting Account Key: ${ACCOUNT_KEY}"

SAS_TOKEN=`az storage account generate-sas --permissions cdlruwap --account-name ${STORAGE_ACCOUNT} --services b --resource-types sco --expiry ${TEST_RUN_DATE} --account-key ${ACCOUNT_KEY} --output tsv`
echo "Getting SAS token: ${SAS_TOKEN}"

mkdir /tmp/$TEST_RUN_DATE
echo "TEST ${TEST_RUN_DATE}" > /tmp/$TEST_RUN_DATE/test.txt
echo "Syncing test file to container: ${CONTAINER_NAME}"
RESULT=`azcopy sync /tmp/$TEST_RUN_DATE https://${STORAGE_ACCOUNT}.blob.core.windows.net/${CONTAINER_NAME}?${SAS_TOKEN} --recursive`
echo $RESULT
rm -rf /tmp/$TEST_RUN_DATE


