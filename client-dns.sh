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
		echo "=> Configuring DNS Resolution"
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

echo "Script $0 complete."
exit 0