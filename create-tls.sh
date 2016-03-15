#!/bin/bash

TLSHOME="/etc/docker/tls"
BITS=2048

echo " => Ensuring config directory exists..."
if [ ! -d $TLSHOME ]; then
	mkdir -p $TLSHOME
fi
cd $TLSHOME
echo " => Verifying ca.srl"
if [ ! -f "ca.srl" ]; then
	echo " => Creating ca.srl"
	echo 01 > ca.srl
fi

# Check for ca-key.pem file
echo " => Verifying ca-key.pem"
if [ ! -f "ca-key.pem" ]; then
	echo " => Generating CA key"
	openssl genrsa -out ca-key.pem $BITS
fi

# Check for ca.pem file
	echo " => Verifying ca.pem"
if [ ! -f "ca.pem" ]; then
	echo " => Generating CA certificate"
	openssl req -new -key ca-key.pem -x509 -days 3650 -nodes -subj "/CN=cfrmgr.proserveau.local" -out ca.pem
fi

if [ -f ca.pem ] && [ -f ca-key.pem ]; then
	# Create the client certificate
	echo " => Generating client key"
	openssl genrsa -out client-key.pem $BITS
	echo " => Generating client CSR"
	openssl req -subj "/CN=docker.client" -new -key client-key.pem -out client.csr
	echo " => Creating extended key usage"
	echo "extendedKeyUsage = clientAuth" > extfile.cnf
	echo " => Signing client CSR with CA"
	openssl x509 -req -days 3650 -in client.csr -CA ca.pem -CAkey ca-key.pem -out client-cert.pem -extfile extfile.cnf

	# Create the Docker Swarn certificate
	echo " => Generating swarm key"
	openssl genrsa -out swarm-key.pem $BITS
	echo " => Genereating swarm CSR"
	openssl req -subj "/CN=swarm.proserveau.local" -new -key swarm-key.pem -out swarm.csr
	echo " => Creating extended key usage"
	echo "extendedKeyUsage = clientAuth,serverAuth" > extfile.cnf
	echo " => Signing swarm CSR with CA"
	openssl x509 -req -days 3650 -in swarm.csr -CA ca.pem -CAkey ca-key.pem -out swarm-cert.pem -extfile extfile.cnf

	# Create the Docker Engine certificates
	echo " => Generating server key for docker0.proserveau.local."
	openssl genrsa -out docker0.proserveau.local-key.pem $BITS
	echo " => Generating server CSR"
	openssl req -subj "/CN=docker0.proserveau.local" -new -key docker0.proserveau.local-key.pem -out docker0.proserveau.local.csr
	echo " => Signing server CSR with CA"
	openssl x509 -req -days 3650 -in docker0.proserveau.local.csr -CA ca.pem -CAkey ca-key.pem -out docker0.proserveau.local-cert.pem

	echo " => Generating server key for docker1.proserveau.local."
	openssl genrsa -out docker1.proserveau.local-key.pem $BITS
	echo " => Generating server CSR"
	openssl req -subj "/CN=docker1.proserveau.local" -new -key docker1.proserveau.local-key.pem -out docker1.proserveau.local.csr
	echo " => Signing server CSR with CA"
	openssl x509 -req -days 3650 -in docker1.proserveau.local.csr -CA ca.pem -CAkey ca-key.pem -out docker1.proserveau.local-cert.pem

	echo " => Generating server key for docker2.proserveau.local."
	openssl genrsa -out docker2.proserveau.local-key.pem $BITS
	echo " => Generating server CSR"
	openssl req -subj "/CN=docker2.proserveau.local" -new -key docker2.proserveau.local-key.pem -out docker2.proserveau.local.csr
	echo " => Signing server CSR with CA"
	openssl x509 -req -days 3650 -in docker2.proserveau.local.csr -CA ca.pem -CAkey ca-key.pem -out docker2.proserveau.local-cert.pem
	
	# Copy certificates to the Docker hosts
	scp -i ~/.ssh/devops.key ca*.pem docker0*pem ubuntu@docker0.proserveau.local:~/
	scp -i ~/.ssh/devops.key ca*.pem docker1*pem swarm*pem ubuntu@docker0.proserveau.local:~/
	scp -i ~/.ssh/devops.key ca*.pem docker2*pem ubuntu@docker0.proserveau.local:~/

fi

exit 0
