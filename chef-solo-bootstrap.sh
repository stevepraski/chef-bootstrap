#!/bin/bash
set -e

# parameter shuffle
for i in "$@"; do
  case $i in
    -p=*|--port=*)
    PORT="${i#*=}"
    shift
    ;;
    -s=*|--server=*)
    SERVER="${i#*=}"
    shift
    ;;
    -i=*|--sshkey=*)
    SSH_KEY="${i#*=}"
    shift
    ;;
    -u=*|--user=*)
    ADMIN="${i#*=}"
    shift
    ;;
    *)
    # unknown parameter
    ;;
  esac
done

if [[ -z ${ADMIN} ]]; then
  echo " --> INFO: Assuming SSH user 'sysop'"
  ADMIN="sysop"
fi

if [[ -z ${PORT} ]]; then
  echo " --> INFO: Assuming port '22'"
  PORT="22"
fi

if [[ -z ${SSH_KEY} ]]; then
  echo " --> INFO: No SSH key specified"
else
  SSH_KEY_PATH="${HOME}/.ssh/${SSH_KEY}"
  if [[ ! -f $SSH_KEY_PATH ]]; then
    echo " --> WARNING: Specified SSH key not found in: '${HOME}/.ssh/', trying absolute path,..."
    SSH_KEY_PATH="${SSH_KEY}"
    if [[ ! -f $SSH_KEY_PATH ]]; then
      echo "FATAL: Specified SSH key not found!"
      exit 1
    fi
  fi
 SSH_ID_PARAM="-i ${SSH_KEY_PATH}"
fi

if [[ -z ${SERVER} ]]; then
  echo "FATAL: No server IP/Hostname specified!"
  exit 1
fi

if [[ "${PORT}" == "22" && "${SERVER}" == "localhost" ]]; then
  echo "FATAL: Never run locally!"
  exit 1
fi

if [[ ! -f chef-solo.json ]]; then
  echo "FATAL: 'chef-solo.json' not found!"
  exit 1
fi

BERKS=`which berks`
if [[ -z ${BERKS} ]]; then
  echo "FATAL: 'berks' command not found in path!"
  exit 1
fi

if [[ ! -f Berksfile ]]; then
  echo "FATAL: Berksfile not found!"
  exit 1
fi

# vendor cookbooks
if [[ -d "berks-cookbooks" ]]; then
  echo " --> WARNING: old berks-cookbook directory found"
  echo " +-> Skipping cookbook vendoring to prevent recursive inclusion"
else
  ${BERKS} vendor -b Berksfile
  echo " +-> Cookbooks vendored with Berkshelf"
fi

SSH_PARAMS="-p ${PORT} ${SSH_ID_PARAM} ${ADMIN}@${SERVER}"
RSYNC_PARAMS="-rltD -e \"ssh ${SSH_ID_PARAM} -p ${PORT}\" --rsync-path=\"sudo rsync\""

# setup chef directory structure
ssh ${SSH_PARAMS} "sudo mkdir -p /etc/chef /var/chef/cookbooks"
echo " +-> Chef directories created"

# rsync
ssh ${SSH_PARAMS} "if which yum; then sudo yum -y install rsync; else sudo apt-get install -y rsync; fi;"
echo " +-> 'rsync' installed or present"

rsync -rltD -e "ssh ${SSH_ID_PARAM} -p ${PORT}" --rsync-path="sudo rsync" berks-cookbooks/ ${ADMIN}@${SERVER}:/var/chef/cookbooks
echo " +-> Cookbooks transfered"

# attributes and runlist
rsync -rltD -e "ssh ${SSH_ID_PARAM} -p ${PORT}" --rsync-path="sudo rsync" chef-solo.json ${ADMIN}@${SERVER}:/etc/chef
echo " +-> 'chef-solo.json' transfered "

# chef
ssh ${SSH_PARAMS} "if [[ ! -d /opt/chef/embedded ]]; then sudo bash -c \"wget https://omnitruck.chef.io/install.sh -O - | bash -s\"; fi;"
echo " +-> Chef clients installed"

# converge
ssh ${SSH_PARAMS} "bash -c \"cd /var/chef && sudo chef-client -j /etc/chef/chef-solo.json -z\""
echo " +-> Chef Solo executed successfully"
