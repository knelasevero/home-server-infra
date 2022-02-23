#!/bin/bash

set -o errexit
set -o pipefail

if [ -z "$ENVIRONMENT" ]
then
  echo "If you want to suppress this input, run 'export ENVIRONMENT=<ENVIRONMENT_NAME>' on the command line"
  echo -n 'Input ENVIRONMENT: '
  read -r ENVIRONMENT
fi

if [ -z "$server_fqdn" ]
then
  echo "If you want to suppress this input, run 'export server_fqdn=<FQDN>' on the command line"
  echo -n 'Input server_fqdn: '
  read -r server_fqdn
fi

if [ -z "$ansible_user" ]
then
  echo "If you want to suppress this input, run 'export domain=<domain>' on the command line"
  echo -n 'Input domain: '
  read -r ansible_user
fi

TEMPLATES_DIR="ansible/inventories/templates"
INVENTORY_DIR="ansible/inventories/${ENVIRONMENT}"
envsubst_variables='${server_fqdn} ${ansible_user}'

set -o nounset

mkdir -p "${INVENTORY_DIR}/group_vars"
export server_fqdn
export ansible_user

cat "${TEMPLATES_DIR}/hosts" | envsubst "${envsubst_variables}" > "${INVENTORY_DIR}/hosts"
for i in $(ls "${TEMPLATES_DIR}/group_vars")
do
  cat "${TEMPLATES_DIR}/group_vars/${i}" | envsubst "${envsubst_variables}" > "${INVENTORY_DIR}/group_vars/${i}"
done
