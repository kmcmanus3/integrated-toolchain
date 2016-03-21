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

# Install Docker Engine
apt-get -y install python-pip
curl -sSL https://get.docker.com/ | sh
pip install docker-py

# Stop Docker Service
service docker stop

echo "export DOCKER_CERT_PATH=\$HOME/.docker" | tee -a /etc/profile.d/docker
echo "export DOCKER_HOST=tcp://$HOSTNAME.proserveau.local:2376" | tee -a /etc/profile.d/docker
echo "export DOCKER_TLS_VERIFY=1" | tee -a /etc/profile.d/docker

echo "export DOCKER_OPTS=\"--tls=true --tlscacert=/etc/docker/tls/ca.pem --tlscert=/etc/docker/tls/$HOSTNAME.proserveau.local-cert.pem --tlskey=/etc/docker/tls/$HOSTNAME.proserveau.local-key.pem -H=tcp://0.0.0.0:2376 -H=unix:///var/run/docker.sock --insecure-registry=cfgmgr.proserveau.local:5000\"" | tee -a /etc/default/docker

if [ ! -d ~/.docker ]; then
	mkdir -p ~/.docker
fi
cp /etc/docker/tls/ca*pem ~/.docker
cp /etc/docker/tls/client*pem ~/.docker

# Start Docker Service
service docker start

# Install Docker Registry
docker --tls=true -H tcp://cfgmgr.proserveau.local:2376 pull registry:2
docker --tls=true -H tcp://cfgmgr.proserveau.local:2376 run -d -p 5000:5000 --name registry registry:2

# Get the local IP of eth0
export HOSTIP=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}'`

# Install Etcd
docker --tls=true -H tcp://cfgmgr.proserveau.local:2376 pull quay.io/coreos/etcd:v2.0.8
docker --tls=true -H tcp://cfgmgr.proserveau.local:2376 run -d -p 4001:4001 -p 2380:2380 -p 2379:2379 --name etcd quay.io/coreos/ectd:v2.0.8 \
-name etcd0  -advertise-client-urls http://${HOSTIP}:2379,http://${HOSTIP}:4001 \
-listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
-initial-advertise-peer-urls http://${HOSTIP}:2380 \
-listen-peer-urls http://0.0.0.0:2380 \
-initial-cluster-token etcd-cluster-1 \
-initial-cluster etcd0=http://${HOSTIP}:2380 \
-initial-cluster-state new

# Get Docker Status
docker --tls=true -H tcp://cfgmgr.proserveau.local:2376 info