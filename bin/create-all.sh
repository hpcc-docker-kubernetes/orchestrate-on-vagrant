#!/bin/bash

SCRIPT_DIR=$(dirname $0)
ROOT_DIR=${SCRIPT_DIR}/..

source ${ROOT_DIR}/env


kubectl create -f ${ROOT_DIR}/roxie-rc.yaml
kubectl create -f ${ROOT_DIR}/thor-rc.yaml
kubectl create -f ${ROOT_DIR}/dali-rc.yaml
kubectl create -f ${ROOT_DIR}/hpcc-ansible.yaml
