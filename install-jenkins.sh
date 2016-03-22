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

JENKINSHOME="/var/lib/jenkins"
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
	echo " => Install Jenkins"
	wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
	sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
	apt-get -y update
	apt-get -y install jenkins ant maven pwauth

	# Create DOCKERCI user
	echo " => Create dockerci user"
	groupadd dockerci
	useradd -p $( echo "$PASSWD" | openssl passwd -1 -salt s%-1d@ -stdin ) -g dockerci dockerci

	# Stop Jenkins Service
	echo " => Stopping Jenkins to perform configuration work"
	service jenkins stop

	# Copy certifcate files
	echo " => Placing certificate files"
	if [ ! -d $JENKINSHOME/.ssh ]; then
		mkdir -p $JENKINSHOME/.ssh
		chown -R jenkins:jenkins $JENKINSHOME/.ssh
		chmod -R 600 $JENKINSHOME/.ssh
	fi
	cp /etc/docker/tls/$PUBLICIP*pem $JENKINSHOME/.ssh
	
	# Copy SSH key for Docker Hosts
	if [ -f ~/.ssh/docker.pem ]; then
		cp ~/.ssh/docker.pem $JENKINSHOME/.ssh
	else
		echo "Could not find ~/.ssh/docker.pem file - please copy this file to $JENKINSHOME/.ssh/"
	fi
	
	# Set Jenkins arguments for ports and certificates
	echo " => Reconfigure Jenkins daemon startup parameters"
	sed -i -e "s/JENKINS_ARGS=/#JENKINS_ARGS=/"
	echo "JENKINS_ARGS=\"--httpPort=-1 --httpsPort=8443 --httpsCertificate=$JENKINSHOME/.ssh/$PUBLICIP-cert.pem --httpsPrivateKey=$JENKINSHOME/.ssh/$PUBLICIP-key.pem\"" | tee -a /etc/default/jenkins
	
	# Add dockerci user
	echo " => Add dockerci user to Jenkins"
	if [ ! -d $JENKINSHOME/users/dockerci ]; then
		mkdir -p $JENKINSHOME/users/dockerci
	fi
	chown jenkins:jenkins $JENKINSHOME/users/dockerci
	cp jenkins-dockerci-config.xml $JENKINSHOME/users/dockerci/config.xml
	chown jenkins:jenkins $JENKINSHOME/users/dockerci/config.xml
	
	# Take Jenkins out of anonymous mode and grant rights to dockerci
	echo " => Turn on Jenkins security and grant rights to dockerci"
	cp jenkins-config.xml $JENKINSHOME/config.xml
	chown jenkins:jenkins $JENKINSHOME/config.xml
	
	# Add GitHub credentials to Jenkins
	echo " => Add Github credentials to Jenkins"
	cp jenkins-credentials.xml $JENKINSHOME/credentials.xml
	chown jenkins:jenkins $JENKINSHOME/credentials.xml	
	
	# Restart Jenkins
	echo " => Starting Jenkins with new configuration"
	service jenkins start

	# Wait while Jenkins gets it shit together
	echo " => Pause for 30 seconds while Jenkins completes its restart."
	sleep 30 

	# Load Jenkins Plugins (NodeJS, Docker, Ansible?)
	echo " => Install Jenkins Plugins: nodejs, git, git-client, github, github-api, docker-commons, docker-build-step"
	java -jar $JENKINSHOME/war/WEB-INF/jenkin-cli.jar -s https://127.0.0.1:8443/ -noCertificateCheck install-plugin nodejs git git-client github github-api docker-commons docker-build-step -deploy --username dockerci --password $PASSWD

	# Set up NodeTest project and job
	echo " => Create the Node-Test job"
	java -jar $JENKINSHOME/war/WEB-INF/jenkin-cli.jar -s https://127.0.0.1:8443/ -noCertificateCheck create-job Node-Test --username dockerci --password $PASSWD < jenkins-job-config.xml
		
fi

echo " => Script $0 complete."
exit 0