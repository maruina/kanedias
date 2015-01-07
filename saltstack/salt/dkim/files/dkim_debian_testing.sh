#!/bin/bash

# Testing repository - main, contrib and non-free branches
echo "deb http://http.us.debian.org/debian testing main non-free contrib" >> /etc/apt/sources.list
echo "deb-src http://http.us.debian.org/debian testing main non-free contrib" >> /etc/apt/sources.list