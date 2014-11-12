#!/bin/bash

SALT_CALL=`command -v salt-call`
ROOT_DIR=/root

if SALT_CALL; then
    echo 'Saltstack already installed'
else
    wget -O $ROOT_DIR/install_salt.sh https://bootstrap.saltstack.com
    sh $ROOT_DIR/install_salt.sh -M -N
fi
