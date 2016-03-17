#!/bin/bash

# Update repositories to get the right version of Ansible (1.9)
apt-get -y install software-properties-common
apt-add-repository -y ppa:ansible/ansible-1.9
apt-get -y update
apt-get -y ansible

# Copy Ansible patched files

cp ./etcd.py /usr/share/pyshared/ansible/runner/lookup_plugins/
cp ./docker.py /usr/shared/pyshared/ansible/modules/core/cloud/

# Populate /etc/ansible file structure

cp ./ansible.tar.gz /etc/ansible
cd /etc/anisble
tar -zxvf ansible.tar.gz

# Process args and 