#! /bin/sh


domain=$1
port=$2

if [ "$port" = "" ]; then
	port="443"
fi

# Using sed
# echo | openssl s_client -connect bytema.re:443 2>/dev/null | openssl x509 -noout -fingerprint -sha256 -inform pem | sed -e "s/[:]//g" -e "s/^.*=//"

# Get server certificate fingerprint
server_cert=$(echo | openssl s_client -connect $domain:$port 2>/dev/null | openssl x509 -noout -fingerprint -sha256 -inform pem | tr -d [:] | cut -d "=" -f2)

#echo "$server_cert"

if [ "$server_cert" = "" ]; then
	echo "error : could not compute fingerprint from server certificate"
	exit 1
fi



# Get DNS TLSA record hash
dns_record_hash=$(dig +dnssec +noall +answer +multi _$port._tcp.$domain. TLSA | tr -d [:space:] | cut -d "(" -f2 | cut -d ")" -f1)

#echo "$dns_record_hash"

if [ "$dns_record_hash" = "" ]; then
	echo "error : could not pull TLSA record from DNS (maybe it's not present or not synced)"
	exit 1
fi

if [ "$server_cert" = "$dns_record_hash" ]; then
	echo "DANE/TLSA record matches server certificate"
else
	echo "error : DANE/TLSA record does NOT match server certificate"
fi
