#!/bin/bash

# Basic "rsync" test, usage:
# ./rsync.sh <EXAMPLE_TENANT_SA_MAIL> <TENANT_ID> <CLIENT_ID> <SUBSCRIPTION_ID> <RESOURCE_GROUP> <STORAGE_ACCOUNT> <CONTAINER_NAME>

EXAMPLE_TENANT_SA_MAIL=$1
TENANT_ID=$2
CLIENT_ID=$3
SUBSCRIPTION_ID=$4
RESOURCE_GROUP=$5
STORAGE_ACCOUNT=$6
CONTAINER_NAME=$7

TEST_RUN_DATE=`date +"%Y-%m-%dT%H:%M:%SZ"`

# get federated token
GPT_TOKEN=`gcloud auth print-identity-token --impersonate-service-account=${EXAMPLE_TENANT_SA_MAIL} --audiences=api://AzureADTokenExchange`
echo ${GPT_TOKEN}

# login with federated credential token: notice the `--allow-no-subscriptions` flag
az login --service-principal \
 -t ${TENANT_ID} \
 -u ${CLIENT_ID} \
 --federated-token ${GPT_TOKEN} \
 --allow-no-subscriptions \
# now, set the subscription to be able to access storage resources: the Azure Entra ID App
# does not have access to the subscription by default
az account set --subscription ${SUBSCRIPTION_ID}


: '
# get account key to later be able to generate SAS token to run the "sync" command
ACCOUNT_KEY=`az storage account keys list \
  --account-name ${STORAGE_ACCOUNT} \
  --resource-group ${RESOURCE_GROUP} \
  --query '[0].value' -o tsv --debug`
echo "Getting Account Key: ${ACCOUNT_KEY}"

SAS_TOKEN=`az storage account generate-sas \
  --permissions cdlruwap \
  --account-name ${STORAGE_ACCOUNT} \
  --services b --resource-types sco \
  --expiry ${TEST_RUN_DATE} \
  --account-key ${ACCOUNT_KEY} \
  --output tsv`
echo "Getting SAS token: ${SAS_TOKEN}"
'

SAS_TOKEN=`az storage container generate-sas \
  --account-name ${STORAGE_ACCOUNT} \
  --as-user --auth-mode login \
  --expiry ${TEST_RUN_DATE} \
  --name ${CONTAINER_NAME} \
  --permissions rw`
echo "Getting SAS token: ${SAS_TOKEN}"

FILENAME=test-${TEST_RUN_DATE}.txt
echo "TEST ${TEST_RUN_DATE}" > /tmp/${FILENAME}
echo "Copying test file to container: ${CONTAINER_NAME}"
RESULT=`azcopy copy /tmp/${FILENAME} https://${STORAGE_ACCOUNT}.blob.core.windows.net/${CONTAINER_NAME}/${FILENAME}?${SAS_TOKEN} --recursive`
echo $RESULT
rm /tmp/${FILENAME}





