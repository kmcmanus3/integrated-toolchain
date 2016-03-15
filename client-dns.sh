#!/bin/bash

function usage () {
	echo "Usage: $0 --dns <DNS IP> --domain <DOMAIN NAME>"
	exit 1
}

DNSSERVER=""
DOMAINNAME=""

if [ "$#" -eq 4 ]; then

	while [ $# -gt 0 ]; do
		key="$1"
		case $key in
			--dns)
				DNSSERVER=$2
				shift
				;;
			--domain)
				DOMAINNAME=$2
				shift
				;;
			*)
				;;
		esac
		shift
	done
	
	if [ $DNSSERVER != "" ] && [ $DOMAINNAME != "" ]; then
		echo "nameserver $DNSSERVER" | sudo tee /etc/resolv.conf
		echo "domain $DOMAINNAME" | sudo tee -a /etc/resolv.conf
		echo "search $DOMAINNAME" | sudo tee -a /etc/resolv.conf
		resolvconf --disable-updates
	else
		usage
	fi
else
	usage
fi

exit 0