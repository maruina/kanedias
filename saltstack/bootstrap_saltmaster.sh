#!/bin/bash

salt_call=`command -v salt-call`
wget=`command -v wget`
yum=`command -v yum`
apt=`command -v apt`
root_dir=/root

# Install wget if missing
if [[ ${wget} ]]; then
    echo 'wget already installed'

else
    if [[ ${yum} ]]; then
        yum install -y wget
    elif [[ ${apt} ]]; then
        apt-get install -y wget
    fi
fi

if [[ ${salt_call} ]]; then
    echo 'Saltmaster already installed'
else
    wget -O ${root_dir}/install_salt.sh https://bootstrap.saltstack.com
    sh ${root_dir}/install_salt.sh -M -N
fi