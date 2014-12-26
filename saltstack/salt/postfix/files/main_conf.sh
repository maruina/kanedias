#!/bin/bash

echo "{{ salt['pillar.get']('postfix:fqdn') }}" > /etc/mailname