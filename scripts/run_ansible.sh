#!/bin/bash
# You will need to be connected to the VPN
# before running this script.

set -o errexit
set -o pipefail

pushd "${0%/*}/.."

# Explanation: you can provide the params in three ways:
# 1) Input them when prompted by the script
# 2) Set environment variables (as listed below)
# 3) Use env file: ./tmp/run_ansible.env
#    The content of that file should follow:
#      export ENVIRONMENT="<ENV_NAME>"
#      export TAGS="<ANSIBLE_TAGS_TO_RUN>"
#      export TASK="<ANSIBLE_TASK_TO_START_AT>" # You can ommit it to run all tasks

echo
echo "Sourcing env variables from ./tmp/run_ansible.env (if exists)"
echo

if [ -f ./tmp/run_ansible.env ]; then
  # shellcheck source=/dev/null
  source ./tmp/run_ansible.env
fi


echo
echo "Rendering ansible inventory"
echo

./scripts/render_inventory.sh

if [ -z "$ENVIRONMENT" ]; then
  echo "If you want to suppress this input, run 'export ENVIRONMENT=<ENVIRONMENT_NAME>' on the command line"
  echo -n 'Input ENVIRONMENT: '
  read -r ENVIRONMENT
  export ENVIRONMENT
fi

if [ -z "$TAGS" ]; then
  echo "If you want to suppress this input, run 'export TAGS=<ANSIBLE_TAGS>' on the command line"
  echo -n 'Input TAGS: '
  read -r TAGS
  export TAGS
fi


echo "ENVIRONMENT=${ENVIRONMENT}"
echo "TAGS=${TAGS}"
echo "TASK=${TASK}"


export ANSIBLE_STDOUT_CALLBACK=yaml

pushd ansible

echo
echo "Run ansible"
echo

INVENTORY="inventories/${ENVIRONMENT}/hosts"


if [ -n "$TAGS" ] && [ -n "$TASK" ]; then
  ansible-inventory -i $INVENTORY --graph

  ansible-playbook -vv -i $INVENTORY site.yml\
    --tags "${TAGS}" --start-at-task="${TASK}" "$@"

else
  ansible-inventory -i $INVENTORY --graph

  ansible-playbook -vv -i $INVENTORY site.yml\
    --tags "${TAGS}" "$@"
fi

popd
popd
