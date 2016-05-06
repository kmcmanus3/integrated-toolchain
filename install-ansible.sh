#!/bin/bash

# COPYRIGHT (C) 2016 CSC, INC.  ALL RIGHTS RESERVED.  CONFIDENTIAL
# AND PROPRIETARY.

# ALL SOFTWARE, INFORMATION AND ANY OTHER RELATED COMMUNICATIONS (COLLECTIVELY,
# "WORKS") ARE CONFIDENTIAL AND PROPRIETARY INFORMATION THAT ARE THE EXCLUSIVE
# PROPERTY OF CSC.  ALL WORKS ARE PROVIDED UNDER THE APPLICABLE
# AGREEMENT OR END USER LICENSE AGREEMENT IN EFFECT BETWEEN YOU AND
# CSC.  UNLESS OTHERWISE SPECIFIED IN THE APPLICABLE AGREEMENT, ALL
# WORKS ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND EITHER EXPRESSED OR
# IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  ALL USE, DISCLOSURE
# AND/OR REPRODUCTION OF WORKS NOT EXPRESSLY AUTHORIZED BY CSC IS
# STRICTLY PROHIBITED.

function usage () {
	echo "Usage: $0 --sshuser <SSH User Account> [--loadbalance <aws | haproxy>] [--ec2region <AWS EC2 Region>] [--awsaccesskey <AWS Access Key>] [--awssecretkey <AWS Secret Key>]"
	exit 1
}

if [ $# -gt 1 ]; then

	# Update repositories to get the right version of Ansible (1.9)
	echo " => Installing Ansible 1.9"
	apt-get -y install software-properties-common
	apt-add-repository -y ppa:ansible/ansible-1.9
	apt-get -y update
	apt-get -y install ansible

	# Copy Ansible patched files
	echo " => Patching Ansible for Docker and Etcd"
	cp ./etcd.py /usr/share/pyshared/ansible/runner/lookup_plugins/
	cp ./docker.py /usr/share/pyshared/ansible/modules/core/cloud/docker/

	# Populate /etc/ansible file structure
	echo " => Unpacking the Ansible configuration files"
	cp ./ansible.tar.gz /etc/ansible/
	cd /etc/ansible
	tar -zxvf ansible.tar.gz
	rm -f ansible.tar.gz

	while [ $# -gt 0 ]; do
		key=$1
		case $key in
			--sshuser)
				sed -i -e "s/SSHUSER/$2" /etc/ansible/group_vars/all
				shift
				;;
			--loadbalance)
				cp /etc/ansible/docker-canary.yml.$2 /etc/ansible/docker-canary.yml
				cp /etc/ansible/docker-prod.yml.$2 /etc/ansible/docker-prod.yml
				shift
				;;
			--ec2region)
				sed -i -e "s/EC2REGION/$2" /etc/ansible/group_vars/all
				shift
				;;
			--awsaccesskey)
				sed -i -e "s/AWSACCESSKEY/$2" /etc/ansible/group_vars/all
				sed -i -e "s/EC2ACCESSKEY/$2" /etc/ansible/group_vars/all
				shift
				;;
			--awssecretkey)
				sed -i -e "s/AWSSECRETKEY/$2" /etc/ansible/group_vars/all
				sed -i -e "s/EC2SECRETKEY/$2" /etc/ansible/group_vars/all
				shift
				;;
			*)
				usage
				;;
		esac
		shift
	done
	
else
	usage

fi

	echo " => Script $0 complete."
exit 0