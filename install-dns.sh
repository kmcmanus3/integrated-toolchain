#!/bin/bash

if [ "$#" -gt 0 ]; then

	# Install BIND9
	apt-get -y install bind9

	# Stop BIND9 Service
	service bind9 stop

	# Adjust BIND configuration, add proserveau.local zone and records.
	cp named.conf.options /etc/bind/named.conf.options
	cp named.conf.local /etc/bind/named.conf.local
	cp proserveau.local.db /etc/bind/proserveau.local.db
	
	while [ $# -gt 0 ]; do
		key="$1"
		IPADDR="$2"
		case $key in
			--dns)
				RECORD="NS1ADDR"
				shift
				;;
			--forwarder)
				RECORD="FWDADDR"
				shift
				;;
			--docker0)
				RECORD="D0ADDR"
				shift
				;;
			--docker1)
				RECORD="D1ADDR"
				shift		
				;;
			--docker2)
				RECORD="D2ADDR"
				shift
				;;
			*)
				;;
		esac
		sed -i -e "s/$RECORD/$IPADDR/" /etc/bind/proserveau.local
		sed -i -e "s/$RECORD/$IPADDR/" /etc/bind/named.conf.options
		shift
	done

	# Start BIND9 Service
	service bind start

else
	echo "Usage: ./install-dns.sh --dns <DNS IP> --forwarder <FWD IP> --docker0 <DOCKER0 IP> --docker1 <DOCKER1 IP> --docker2 <DOCKER2 IP>"
	exit 1

fi

exit 0