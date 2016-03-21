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

function usage() {
	echo "Usage: $0 --dns <DNS IP> --forwarder <FWD IP> --docker0 <DOCKER0 IP> --docker1 <DOCKER1 IP> --docker2 <DOCKER2 IP>"
	exit 1
}

NS1ADDR=""
FWDADDR=""
D0ADDR=""
D1ADDR=""
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
		case $key in
			--dns)
				NS1ADDR="$2"
				shift
				;;
			--forwarder)
				FWDADDR="$2"
				shift
				;;
			--docker0)
				D0ADDR="$2"
				shift
				;;
			--docker1)
				D1ADDR="$2"
				shift		
				;;
			--docker2)
				D2ADDR="$2"
				shift
				;;
			*)
				;;
		esac
		shift
	done

	if  [ $NS1ADDR != "" ] && [ $FWDADDR != "" ] && [ $D0ADDR != "" ] && [ $D1ADDR != "" ] && [ $D2ADDR != "" ]; then
		sed -i -e "s/NS1ADDR/$NS1ADDR/" /etc/bind/proserveau.local.db
		sed -i -e "s/NS1ADDR/$NS1ADDR/" /etc/bind/named.conf.options
		sed -i -e "s/FWDADDR/$FWDADDR/" /etc/bind/named.conf.options
		sed -i -e "s/D0ADDR/$D0ADDR/" /etc/bind/proserveau.local.db
		sed -i -e "s/D0ADDR/$D0ADDR/" /etc/bind/named.conf.options
		sed -i -e "s/D1ADDR/$D1ADDR/" /etc/bind/proserveau.local.db
		sed -i -e "s/D1ADDR/$D1ADDR/" /etc/bind/named.conf.options
		sed -i -e "s/D2ADDR/$D2ADDR/" /etc/bind/proserveau.local.db
		sed -i -e "s/D2ADDR/$D2ADDR/" /etc/bind/named.conf.options
	else
		usage
	fi

	# Start BIND9 Service
	service bind9 start

else
	usage

fi

exit 0