#!/bin/bash

# Install Docker Engine
apt-get -y install python-pip
curl -sSL https://get.docker.com/ | sh
pip install docker-py

# Stop Docker Service
service docker stop

# Setup for TLS
if [ ! -d /etc/docker/tls ]; then
	mkidr -p /etc/docker/tls
fi

cp ~/ca*pem ~/docker*pem /etc/docker/tls

echo "export DOCKER_OPTS=\"--tls=true --tlscacert=/etc/docker/tls/ca.pem --tlscert=/etc/docker/tls/$HOSTNAME.proserveau.local-cert.pem --tlskey=/etc/docker/tls/$HOSTNAME.proserveau.local-key.pem -H=tcp://0.0.0.0:2376 -H=unix:///var/run/docker.sock --insecure-registry=jenkins.proserveau.local:5000\"" | tee -a /etc/default/docker

service docker start

# Launch Registrator Service
if [ $HOSTNAME != "docker0" ]; then 
	docker --tls=true -H tcp://$HOSTNAME.proserveau.local:2376 pull gliderlabs:registrator
	docker --tls=true -H tcp://$HOSTNAME.proserveau.local:2376 run -d --name=registrator --net=host --volume=/var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator:latest etcd://cfgmgr.proserveau.local:4001/services
fi

# Get Docker Engine Status
docker --tls=true -H tcp://$HOSTNAME.proserveau.local:2376 info