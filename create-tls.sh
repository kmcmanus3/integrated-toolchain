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
	echo "Usage: $0 --publicip <Jenkins Public IP>"
	exit 1
}

if [ $# -eq 2 ] && [ $1 == "--publicip" ]; then
	PUBLICIP="$2"
else
	usage
fi

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

	# Create the PUBLICIP certificate
	echo " => Generating server key for Jenkins on the public IP."
	openssl genrsa -out $PUBLICIP-key.pem $BITS
	echo " => Generating server CSR"
	openssl req -subj "/CN=$PUBLICIP" -new -key $PUBLICIP-key.pem -out $PUBLICIP.csr
	echo " => Signing server CSR with CA"
	openssl x509 -req -days 3650 -in $PUBLICIP.csr -CA ca.pem -CAkey ca-key.pem -out $PUBLICIP-cert.pem
	
	# Create the Docker Swarn certificate
	echo " => Generating Docker Swarm key"
	openssl genrsa -out swarm-key.pem $BITS
	echo " => Genereating swarm CSR"
	openssl req -subj "/CN=swarm.proserveau.local" -new -key swarm-key.pem -out swarm.csr
	echo " => Creating extended key usage"
	echo "extendedKeyUsage = clientAuth,serverAuth" > extfile.cnf
	echo " => Signing swarm CSR with CA"
	openssl x509 -req -days 3650 -in swarm.csr -CA ca.pem -CAkey ca-key.pem -out swarm-cert.pem -extfile extfile.cnf

	# Create the Docker Engine certificates
	echo " => Generating server key for cfgmgr.proserveau.local."
	openssl genrsa -out cfgmgr.proserveau.local-key.pem $BITS
	echo " => Generating server CSR"
	openssl req -subj "/CN=cfgmgr.proserveau.local" -new -key cfgmgr.proserveau.local-key.pem -out cfgmgr.proserveau.local.csr
	echo " => Signing server CSR with CA"
	openssl x509 -req -days 3650 -in cfgmgr.proserveau.local.csr -CA ca.pem -CAkey ca-key.pem -out cfgmgr.proserveau.local-cert.pem

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
	scp -i ~/.ssh/docker.pem ca*.pem docker0*pem ubuntu@docker0.proserveau.local:~/
	scp -i ~/.ssh/docker.pem ca*.pem docker1*pem swarm*pem ubuntu@docker0.proserveau.local:~/
	scp -i ~/.ssh/docker.pem ca*.pem docker2*pem ubuntu@docker0.proserveau.local:~/

fi

echo " => Script $0 complete."
exit 0
