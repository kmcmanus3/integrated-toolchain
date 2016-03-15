#!/bin/bash

# Generate the Swarm Token
SWARMTOKEN=`docker --tls=true -H tcp://docker1.proserveau.local:2376 run --rm swarm create`

# Join the Docker Engines to the Swarm
docker --tls=true -H tcp://docker1.proserveau.local:2376 run -d swarm join --addr docker1.proserveau.local token://$SWARMTOKEN
docker --tls=true -H tcp://docker2.proserveau.local:2376 run -d swarm join --addr docker2.proserveau.local token://$SWARMTOKEN

# Run the Swarm Manager
docker --tls=true -H tcp://docker1.proserveau.local:2376 run -d -v /etc/docker/tls:/etc/docker/tls:ro -t -p 7000:2375 swarm manage --tls=true --tlscacert=/etc/docker/tls/ca.pem --tlscert=/etc/docker/tls/swarm-cert.pem --tlskey=/etc/docker/tls/swarm-key.pem token://$SWARMTOKEN

# Output the Swarm Status
docker --tls=true -H tcp://swarm.proserveau.local:7000 info