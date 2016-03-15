#!/bin/bash

# Install Docker Engine
apt-get -y install python-pip
curl -sSL https://get.docker.com/ | sh
pip install docker-py

# Stop Docker Service
service docker stop

# Setup for TLS
if [ ! -d /etc/docker/tls ]; then
	mkdir -p /etc/docker/tls
fi

cp ~/ca*pem ~/docker*pem /etc/docker/tls

if [ $HOSTNAME == "docker1" ]; then
	cp ~/swarm*pem /etc/docker/tls
fi

if [ ! -d ~/.docker ]; then
	mkdir -p ~/.docker
fi

cp ~/ca*pem ~/.docker

echo "export DOCKER_CERT_PATH=\$HOME/.docker" | tee -a /etc/profile.d/docker
echo "export DOCKER_HOST=tcp://$HOSTNAME.proserveau.local:2376" | tee -a /etc/profile.d/docker
echo "export DOCKER_TLS_VERIFY=1" | tee -a /etc/profile.d/docker

echo "export DOCKER_OPTS=\"--tls=true --tlscacert=/etc/docker/tls/ca.pem --tlscert=/etc/docker/tls/$HOSTNAME.proserveau.local-cert.pem --tlskey=/etc/docker/tls/$HOSTNAME.proserveau.local-key.pem -H=tcp://0.0.0.0:2376 -H=unix:///var/run/docker.sock --insecure-registry=cfgmgr.proserveau.local:5000\"" | tee -a /etc/default/docker

# Start Docker Service
service docker start

# Launch Registrator Service (docker0 does not need Registrator)
if [ $HOSTNAME != "docker0" ]; then 
	docker --tls=true -H tcp://$HOSTNAME.proserveau.local:2376 pull gliderlabs:registrator
	docker --tls=true -H tcp://$HOSTNAME.proserveau.local:2376 run -d --name=registrator --net=host --volume=/var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator:latest etcd://cfgmgr.proserveau.local:4001/services
fi

# Get Docker Engine Status
docker --tls=true -H tcp://$HOSTNAME.proserveau.local:2376 info