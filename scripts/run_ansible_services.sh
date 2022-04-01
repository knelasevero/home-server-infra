#!/bin/bash
# You will need to be connected to the VPN
# before running this script.

set -o errexit
set -o pipefail

pushd "${0%/*}/.."

export ANSIBLE_STDOUT_CALLBACK=yaml

pushd ansible_services

echo
echo "Run ansible"
echo

inventory=""

if [ -z "${INVENTORY}" ]; then
    inventory=${1}   
    if [ -z "${1}" ]; then
    echo "Type the inventory name to execute (dev-cluster or pre-cluster): "
    read -r INVENTORY
    export INVENTORY
    inventory=${INVENTORY}
    fi
fi

ansible-inventory -i inventories/${inventory}/hosts.ini  --graph
ansible-playbook site.yml -vvv -i inventories/${inventory}/hosts.ini

popd
popd
