#!/bin/bash

SCRIPT_DIR=$(dirname $0)
ROOT_DIR=${SCRIPT_DIR}/..

source ${ROOT_DIR}/env

function delete_one()
{
   [ -z "$1" ] && [ -z "$2" ] || [ -z "$3" ] && return
   type=$1
   name=$2
   config_file=$3
   kubectl get $type | grep -q -i "^${name}" 
   if [ $? -eq 0 ]; then
      echo "kubectl delete -f ${config_file}"
      kubectl delete -f ${config_file}
      echo ""
   fi
}


delete_one rc roxie-rc ${ROOT_DIR}/roxie-rc.yaml
delete_one rc thor-rc ${ROOT_DIR}/thor-rc.yaml
delete_one rc dali-rc ${ROOT_DIR}/dali-rc.yaml
delete_one pod hpcc-ansible ${ROOT_DIR}/hpcc-ansible.yaml
