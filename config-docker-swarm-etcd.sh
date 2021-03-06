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

# Generate the Swarm Token
#echo " => Generating Docker Swarm Token"
#SWARMTOKEN=`docker --tls=true -H tcp://docker1.proserveau.local:2376 run --rm swarm create`

# Join the Docker Engines to the Swarm
echo " => Joining Docker Engines to Docker Swarm"
docker --tls=true -H tcp://docker1.proserveau.local:2376 run -d swarm join --addr docker1.proserveau.local:2376 etcd://cfgmgr.proserveau.local:4001/swarm
docker --tls=true -H tcp://docker2.proserveau.local:2376 run -d swarm join --addr docker2.proserveau.local:2376 etcd://cfgmgr.proserveau.local:4001/swarm

# Run the Swarm Manager
echo " => Installing Docker Swarm Manager"
docker --tls=true -H tcp://docker1.proserveau.local:2376 run -d -v /etc/docker/tls:/etc/docker/tls:ro -t -p 7000:2375 swarm manage --tls=true --tlscacert=/etc/docker/tls/ca.pem --tlscert=/etc/docker/tls/swarm-cert.pem --tlskey=/etc/docker/tls/swarm-key.pem etcd://cfgmgr.proserveau.local:4001/swarm

echo " => Pause while Docker Swarm Manager starts"
sleep 5

# Output the Swarm Status
echo " => Docker Swarm Status"
docker --tls=true -H tcp://swarm.proserveau.local:7000 info

echo " => Script $0 complete."
exit 0