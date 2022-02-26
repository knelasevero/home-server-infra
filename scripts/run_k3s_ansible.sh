#!/bin/bash
# You will need to be connected to the VPN
# before running this script.

set -o errexit
set -o pipefail

pushd "${0%/*}/.."

export ANSIBLE_STDOUT_CALLBACK=yaml

pushd ansible_k3s

echo
echo "Run ansible"
echo

ansible-inventory -i inventory/dev-cluster/hosts.ini  --graph
ansible-playbook site.yml -vvv -i inventory/dev-cluster/hosts.ini

popd
popd
