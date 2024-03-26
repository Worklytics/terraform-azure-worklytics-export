#!/bin/bash

# ./upload-blob.sh <EXAMPLE_TENANT_SA_MAIL> <TENANT_ID> <CLIENT_ID> <SUBSCRIPTION_ID> <RESOURCE_GROUP> <STORAGE_ACCOUNT> <CONTAINER_NAME>

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

SAS_TOKEN=`az storage container generate-sas \
  --account-name ${STORAGE_ACCOUNT} \
  --as-user --auth-mode login \
  --expiry ${TEST_RUN_DATE} \
  --name ${CONTAINER_NAME} \
  --permissions rwl \
  -o tsv`
echo "Getting SAS token: ${SAS_TOKEN}"

FILENAME=test-${TEST_RUN_DATE}.txt
echo "TEST ${TEST_RUN_DATE}" > /tmp/${FILENAME}
echo "Copying test file to container: ${CONTAINER_NAME}"
RESULT=`az storage blob upload \
  --account-name ${STORAGE_ACCOUNT} \
  --container-name ${CONTAINER_NAME} \
  --file /tmp/${FILENAME} \
  --name ${FILENAME} \
  --sas-token ${SAS_TOKEN}`
echo $RESULT
rm /tmp/${FILENAME}





