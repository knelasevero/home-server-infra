# home-server-infra

Simple ansible/terraform setup to configure opennebula and some other tools in a home server.

## How to

Copy the example env file to edit its values:

```
cp tmp/run_ansible.env.example tmp/run_ansible.env
```

Edit tmp/run_ansible.env add the values that will make you next ansible run useful:

```
export ENVIRONMENT="homeinfra1"
export TAGS="" # for example  TAGS="common", or TAGS="opennebula" or TAGS="all" or comma separated
#export TASK="" # TASK from which the run will start (for debugging)
export server_fqdn="192.168.10.3" # IP or fqdn of the server
export ansible_user="someuser" # user that ansible will use to ssh to and run commands
```

Run ansible with:

```
./scripts/run_ansible.sh
```

Remember, the user used by ansible should be able to do passwordless sudo and should have your public ssh key in its authorized_keys file.
