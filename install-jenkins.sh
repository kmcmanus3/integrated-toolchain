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
	echo "Usage: $0 --publicip <Jenkins Public IP> [--password <dockerci password>]"
	exit 1
}

PUBLICIP=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}'`

if [ $# -lt 2 ]; then
	usage
else

	# Set the default password for the DOCKERCI user
	PASSWD="thei7Fah4iker:ae"

	while [ $# -gt 0 ]; do
		key="$1"
		case $key in
			--publicip)
				PUBLICIP="$2"
				shift
				;;
			--password)
				PASSWD="$2"
				shift
				;;
			*)
			;;
		esac
		shift
	done
	
	# Install Jenkins
	wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
	sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
	apt-get -y update
	apt-get -y install jenkins ant maven pwauth

	# Create DOCKERCI user
	groupadd dockerci
	useradd -p $( echo "$PASSWD" | openssl passwd -1 -salt s%-1d@ -stdin ) -g dockerci dockerci

	# Configure Jenkins
	service jenkins stop

	# Copy certifcate files
	if [ ! -d /var/lib/jeknkins/.ssh ]; then
		mkdir -p /var/lib/jenkins/.ssh
		chown -R jenkins:jenkins /var/lib/jenkins/.ssh
		chmod -R 600 /var/lib/jenkins/.ssh
	fi
	cp /etc/docker/tls/$PUBLICIP*pem /var/lib/jenkins/.ssh
	
	# Copy SSH key for Docker Hosts
	if [ -f ~/.ssh/docker.pem ]; then
		cp ~/.ssh/docker.pem /var/lib/jenkins/.ssh
	else
		echo "Could not find ~/.ssh/docker.pem file - please copy this file to /var/lib/jenkins/.ssh/"
	fi
	
	# Set Jenkins arguments for ports and certificates
	sed -i -e "s/JENKINS_ARGS=/#JENKINS_ARGS=/"
	echo "JENKINS_ARGS=\"--httpPort=-1 --httpsPort=8443 --httpsCertificate=/var/lib/jenkins/.ssh/$PUBLICIP-cert.pem --httpsPrivateKey=/var/lib/jenkins/.ssh/$PUBLICIP-key.pem\"" | tee -a /etc/default/jenkins
	
	# The following are items that still need to be configured on Jnekins, but have not yet been automated.
	
	# To do: Add DOCKERCI user and configure RBAC for DOCKERCI
	
	# To do: Take Jenkins out of anonymous mode
	
	# To do: Add GitHub credentials to Jenkins
	
	# To do: Load Jenkins Plugins (NodeJS, Docker, Ansible?)

	# To do: Set up NodeTest project and job
	
	service jenkins start
fi