#!/bin/bash

function usage() {
	echo "Usage: $0 --dns <DNS IP> --forwarder <FWD IP> --docker0 <DOCKER0 IP> --docker1 <DOCKER1 IP> --docker2 <DOCKER2 IP>"
	exit 1
}

NS1RECORD=""
NS1ADDR=""
FWDRECORD=""
FWDADDR=""
D0RECORD=""
D0ADDR=""
D1RECORD=""
D1ADDR=""
D2RECORD=""
D2ADDR=""

if [ "$#" -eq 10 ]; then

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
		RECORD=""
		case $key in
			--dns)
				NS1RECORD="NS1ADDR"
				NS1ADDR="$2"
				shift
				;;
			--forwarder)
				FWDRECORD="FWDADDR"
				FWDADDR="$2"
				shift
				;;
			--docker0)
				D0RECORD="D0ADDR"
				D0ADDR="$2"
				shift
				;;
			--docker1)
				D1RECORD="D1ADDR"
				D1ADDR="$1"
				shift		
				;;
			--docker2)
				D2RECORD="D2ADDR"
				D2ADDR="$2"
				shift
				;;
			*)
				;;
		esac
		shift
	done

	if [ $NS1RECORD != "" ] && [ $NS1ADDR != "" ] && [ $FWDRECORD != "" ] && [ $FWDADDR != "" ] && [ $D0RECORD != "" ] && [ $D0ADDR != "" ] && [ $D1RECORD != "" ] && [ $D1ADDR != "" ] && [ $D2RECORD != "" ] && [ $D2ADDR != "" ]; then
		sed -i -e "s/$NS1RECORD/$NS1ADDR/" /etc/bind/proserveau.local
		sed -i -e "s/$NS1RECORD/$NS1ADDR/" /etc/bind/named.conf.options
		sed -i -e "s/$FWDRECORD/$FWDADDR/" /etc/bind/named.conf.options
		sed -i -e "s/$D0RECORD/$D0ADDR/" /etc/bind/proserveau.local
		sed -i -e "s/$D0RECORD/$D0ADDR/" /etc/bind/named.conf.options
		sed -i -e "s/$D1RECORD/$D1ADDR/" /etc/bind/proserveau.local
		sed -i -e "s/$D1RECORD/$D1ADDR/" /etc/bind/named.conf.options
		sed -i -e "s/$D2RECORD/$D2ADDR/" /etc/bind/proserveau.local
		sed -i -e "s/$D2RECORD/$D2ADDR/" /etc/bind/named.conf.options
	else
		usage
	fi

	# Start BIND9 Service
	service bind start

else
	usage

fi

exit 0