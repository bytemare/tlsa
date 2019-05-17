#!/usr/bin/env bash

set -e

# Note that Shell substitution seems not to work with /bin/sh


domain=$1
port=$2

if [ "$port" = "" ]; then
	port="443"
fi

# Using sed
# echo | openssl s_client -connect bytema.re:443 2>/dev/null | openssl x509 -noout -fingerprint -sha256 -inform pem | sed -e "s/[:]//g" -e "s/^.*=//"
#
# Using tr and cut is faster
# server_cert=$(echo | openssl s_client -connect bytema.re:443 2>/dev/null | openssl x509 -noout -fingerprint -sha256 -inform pem | tr -d [:] | cut -d "=" -f2)
#
# Using Shell Substitution is blazing fast


# Get server certificate fingerprint

server_cert_fingerprint=$(echo | openssl s_client -connect "$domain":"$port" 2>/dev/null | openssl x509 -noout -fingerprint -sha256 -inform pem)
server_cert_fingerprint=${server_cert_fingerprint//:/}
server_cert_fingerprint=${server_cert_fingerprint#*=}

#echo "$server_cert_fingerprint"

if [ "$server_cert_fingerprint" = "" ]; then
	echo "error : could not compute fingerprint from server certificate"
	exit 1
fi



# Get DNS TLSA record hash
# dns_record_hash=$(dig +dnssec +noall +answer +multi _$port._tcp.$domain. TLSA | tr -d [:space:] | cut -d "(" -f2 | cut -d ")" -f1)

# Using Shell substituion is faster
dns_record=$(dig +dnssec +noall +answer +multi _"$port"._tcp."$domain". TLSA | tr -d '[:space:]')
dns_record_hash=${dns_record#*\(}
dns_record_hash=${dns_record_hash::-1}

#echo "$dns_record_hash"

if [ "$dns_record_hash" = "" ]; then
	echo "error : could not pull TLSA record from DNS (maybe it's not present or not synced)"
	exit 1
fi

if [ "$server_cert_fingerprint" = "$dns_record_hash" ]; then
	echo "DANE/TLSA record matches server certificate"
else
	echo "error : DANE/TLSA record does NOT match server certificate"
	echo "Certifcate : $server_cert_fingerprint"
	echo "DNS Record : $dns_record_hash"
	printf "\n> If you are sure about your certificate, you may want to change your TLSA DNS entry to 3 0 1 %s" "$server_cert_fingerprint"
fi
