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
	echo "Usage: $0 [--loadbalance AWSELB | HAPROXY]"
	exit 1
}


# Update repositories to get the right version of Ansible (1.9)
echo " => Installing Ansible 1.9"
apt-get -y install software-properties-common
apt-add-repository -y ppa:ansible/ansible-1.9
apt-get -y update
apt-get -y ansible

# Copy Ansible patched files
echo " => Patching Ansible for Docker and Etcd"
cp ./etcd.py /usr/share/pyshared/ansible/runner/lookup_plugins/
cp ./docker.py /usr/shared/pyshared/ansible/modules/core/cloud/

# Populate /etc/ansible file structure
echo " => Unpacking the Ansible configuration files"
cp ./ansible.tar.gz /etc/ansible
cd /etc/anisble
tar -zxvf ansible.tar.gz

if [ $# -eq 2 ] && [ $1 == "--loadbalance" ]; then 

	# Process args and set configuration files
	key="$2"
	case $key in
		AWSELB)
			echo " => Setting AWS ELB Ansible Playbooks" 
			cp /etc/ansible/docker-canary.yml.aws /etc/ansible/docker-canary.yml
			cp /etc/ansible/docker-prod.yml.aws /etc/ansible/docker-prod.yml
			echo " => Edit the files docker-prod.yml and docker-canary.yml in /etc/ansible/ to set the AWS Access and Secret Keys, the AWS Region, and the ELB Name"
			;;
		HAPROXY)
			echo " => Setting HAProxy Ansible Playbooks"
			cp /etc/ansible/docker-canary.yml.haproxy /etc/ansible/docker-canary.yml
			cp /etc/ansible/docker-prod.yml.haproxy /etc/ansible/docker-prod.yml
			;;
		*)
			usage
			;;
	esac

else
	usage

fi

echo " => Script $0 complete."
exit 0