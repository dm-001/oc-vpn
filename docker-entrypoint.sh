#!/bin/bash

# Copy default config files if removed
if [[ ! -e /config/ocserv.conf || ! -e /config/connect.sh || ! -e /config/disconnect.sh || \
	  ! -e /config/sp-metadata.xml || ! -e /config/sso.conf || ! -e /config/profile.xml ]]; then
	echo "$(date) [err] Required config files are missing."
	echo "\t [err] Creating defaults"
	rsync -vzr --ignore-existing "/etc/default/ocserv/" "/config"
fi

chmod a+x /config/*.sh

##### Verify Variables #####

export TUNNEL_MODE=$(echo "${TUNNEL_MODE}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
# Check PROXY_SUPPORT env var
if [[ ! -z "${TUNNEL_MODE}" ]]; then
	echo "$(date) [info] TUNNEL_MODE defined as '${TUNNEL_MODE}'"
else
	echo "$(date) [warn] TUNNEL_MODE not defined,(via -e TUNNEL_MODE), defaulting to 'all'"
	export TUNNEL_MODE="all"
fi

if [[ ${TUNNEL_MODE} == "all" ]]; then
	echo "$(date) [info] Tunnel mode is all, ignoring TUNNEL_ROUTES. If you want to define specific routes, change TUNNEL_MODE to split-include"
elif [[ ${TUNNEL_MODE} == "split-include" ]]; then
	# strip whitespace from start and end of SPLIT_DNS_DOMAINS
	export TUNNEL_ROUTES=$(echo "${TUNNEL_ROUTES}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	# Check SPLIT_DNS_DOMAINS env var and exit if not defined
	if [[ ! -z "${TUNNEL_ROUTES}" ]]; then
		echo "$(date) [info] TUNNEL_ROUTES defined as '${TUNNEL_ROUTES}'"
	else
		echo "$(date) [err] TUNNEL_ROUTES not defined (via -e TUNNEL_ROUTES), but TUNNEL_MODE is defined as split-include"
	fi
fi

export DNS_SERVERS=$(echo "${DNS_SERVERS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
# Check DNS_SERVERS env var
if [[ ! -z "${DNS_SERVERS}" ]]; then
		echo "$(date) [info] DNS_SERVERS defined as '${DNS_SERVERS}'"
	else
		echo "$(date) [warn] DNS_SERVERS not defined (via -e DNS_SERVERS), defaulting to Google and FreeDNS name servers"
		export DNS_SERVERS="8.8.8.8,37.235.1.174,8.8.4.4,37.235.1.177"
fi

export SPLIT_DNS_DOMAINS=$(echo "${SPLIT_DNS_DOMAINS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${SPLIT_DNS_DOMAINS}" ]]; then
	# Check SPLIT_DNS_DOMAINS env var
	if [[ ! -z "${SPLIT_DNS_DOMAINS}" ]]; then
		echo "$(date) [info] SPLIT_DNS_DOMAINS defined as '${SPLIT_DNS_DOMAINS}'"
	else
		echo "$(date) [err] SPLIT_DNS_DOMAINS not defined (via -e SPLIT_DNS_DOMAINS)"
	fi
fi

# Verify GEOBLOCK status
export GEOBLOCK=$(echo "$GEOBLOCK" | awk '{print tolower($0)}')
if [[ ${GEOBLOCK} == "true" ]]; then
	echo "$(date) [info] Geoblocking functions enabled "
	# Make sure the ALLOW_COUNTRY_CODES is defined
	if [[ ! -z "${ALLOW_COUNTRY_CODES}" ]]; then
		# Make sure country codes are uppercase
		export ALLOW_COUNTRY_CODES=$(echo "$ALLOW_COUNTRY_CODES" | awk '{print toupper($0)}')
		echo "$(date) [info] Geoblocking: Allowed country codes are ${ALLOW_COUNTRY_CODES}"
	    else
		echo "$(date) [warn] ALLOW_COUNTRY_CODES not defined. Defaulting to FR DE US GB AU CA NZ" 
		export ALLOW_COUNTRY_CODES="FR DE US GB AU CA NZ"
	fi
else
	echo "$(date) [info] Geoblocking functions disabled"
fi


##### Process Variables #####

if [[ ${TUNNEL_MODE} == "all" ]]; then
	echo "$(date) [info] Tunneling all traffic through VPN"
	sed -i '/^route=/d' /config/ocserv.conf
elif [[ ${TUNNEL_MODE} == "split-include" ]]; then
	echo "$(date) [info] Tunneling routes $TUNNEL_ROUTES through VPN"
	sed -i '/^route=/d' /config/ocserv.conf
	# split comma seperated string into list from TUNNEL_ROUTES env variable
	IFS=',' read -ra tunnel_route_list <<< "${TUNNEL_ROUTES}"
	# process name servers in the list
	for tunnel_route_item in "${tunnel_route_list[@]}"; do
		tunnel_route_item=$(echo "${tunnel_route_item}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
		IP=$(sipcalc ${tunnel_route_item} | awk '/Network address/ {print $4; exit}')
		NETMASK=$(sipcalc ${tunnel_route_item} | awk '/Network mask/ {print $4; exit}')
		TUNDUP=$(cat /config/ocserv.conf | grep "route=${IP}/${NETMASK}")
		if [[ -z "$TUNDUP" ]]; then
			echo "$(date) [info] Adding route=$IP/$NETMASK to ocserv.conf"
			echo "route=$IP/$NETMASK" >> /config/ocserv.conf
		fi
	done
fi


# Add DNS_SERVERS to ocserv conf
sed -i '/^dns =/d' /config/ocserv.conf
# split comma seperated string into list from NAME_SERVERS env variable
IFS=',' read -ra name_server_list <<< "${DNS_SERVERS}"
# process name servers in the list
for name_server_item in "${name_server_list[@]}"; do
	DNSDUP=$(cat /config/ocserv.conf | grep "dns = ${name_server_item}")
	if [[ -z "$DNSDUP" ]]; then
		# strip whitespace from start and end of lan_network_item
		name_server_item=$(echo "${name_server_item}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
		echo "$(date) [info] Adding dns = ${name_server_item} to ocserv.conf"
		echo "dns = ${name_server_item}" >> /config/ocserv.conf
	fi
done

# Process SPLIT_DNS env var
if [[ ! -z "${SPLIT_DNS_DOMAINS}" ]]; then
	sed -i '/^split-dns =/d' /config/ocserv.conf
	# split comma seperated string into list from SPLIT_DNS_DOMAINS env variable
	IFS=',' read -ra split_domain_list <<< "${SPLIT_DNS_DOMAINS}"
	# process name servers in the list
	for split_domain_item in "${split_domain_list[@]}"; do
		DOMDUP=$(cat /config/ocserv.conf | grep "split-dns = ${split_domain_item}")
		if [[ -z "$DOMDUP" ]]; then
			# strip whitespace from start and end of lan_network_item
			split_domain_item=$(echo "${split_domain_item}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
			echo "$(date) [info] Adding split-dns = ${split_domain_item} to ocserv.conf"
			echo "split-dns = ${split_domain_item}" >> /config/ocserv.conf
		fi
	done
fi
if [[ ! -z "${CLIENTNET}" ]]; then
    sed -i "s/^ipv4-network.*$/ipv4-network = ${CLIENTNET}/" /config/ocserv.conf
fi
if [[ ! -z "${CLIENTNETMASK}" ]]; then
    sed -i "s/^ipv4-netmask.*$/ipv4-netmask = ${CLIENTNETMASK}/" /config/ocserv.conf
fi

# Add default domain to vpn config
if [[ ! -z "${DEFAULT_DOMAIN}" ]]; then
	sed -i "s/^default-domain =.*$/default-domain = ${DEFAULT_DOMAIN}/" /config/ocserv.conf
fi

# Enable Geoblocking?
if [[ ${GEOBLOCK} == "true" ]]; then
	sed -i "s/^connect-script =.*$/connect-script = \/config\/geoblock\.sh/" /config/ocserv.conf
else
	sed -i "s/^connect-script =.*$/connect-script = \/config\/connect\.sh/" /config/ocserv.conf
fi

# Add VPN friendly name to AnyConnect profile
if [[ ! -z "${VPN_NAME}" ]]; then
	sed -i "s/<HostName>.\+<\/HostName>/<HostName>${VPN_NAME}<\/HostName>/g" /config/profile.xml
fi

# Add hostname/fqdn to config, sso data and anyconnect profile
if [[ ! -z "${HOSTNAME}" ]]; then
	echo "$(date) [info] Adding hostname: ${HOSTNAME} to config, metadata profile"
	sed -i "s/^hostname.*$/hostname = ${HOSTNAME}/" /config/ocserv.conf
	sed -i "s/https:\/\/[^\/?#]*/https:\/\/${HOSTNAME}/g" /config/sp-metadata.xml
        sed -i "s/<HostAddress>.\+<\/HostAddress>/<HostAddress>${HOSTNAME}<\/HostAddress>/g" /config/profile.xml
fi

##### Get certs if none exist #####
if [ ! -f /config/certs/server-key.pem ] || [ ! -f /config/certs/server-cert.pem ]; then
        # Make sure there's an email address provided
        if [[ -z "${TLS_EMAIL}" ]]; then
            TLS_EMAIL="example@example.com"
        fi
	# No certs found
        if [[ $TLS_TEST = "true" ]]; then
	    echo "$(date) [info] No certificates were found, requesting TEST TLS certificates for ${HOSTNAME} from LetsEncrypt"
	    certbot certonly --standalone --test-cert --agree-tos -n -m $TLS_EMAIL -d $HOSTNAME
        else
	    echo "$(date) [info] No certificates were found, requesting live TLS certificates for ${HOSTNAME} from LetsEncrypt"
	    certbot certonly --standalone --agree-tos -n -m $TLS_EMAIL -d $HOSTNAME
	fi	
	# Copy and rename to /config/certs/server-cert.pem etc
	cp --update -v /etc/letsencrypt/live/$HOSTNAME/fullchain.pem /config/certs/server-cert.pem
	cp --update -v /etc/letsencrypt/live/$HOSTNAME/privkey.pem /config/certs/server-key.pem
	# set up a renewal hook to recopy certs and reload the VPN server upon cert renewal
	echo '#!/bin/bash' > /etc/letsencrypt/renewal-hooks/post/run.sh
	echo "cp --update -v /etc/letsencrypt/live/${HOSTNAME}/fullchain.pem /config/certs/server-cert.pem" >> /etc/letsencrypt/renewal-hooks/post/run.sh
	echo "cp --update -v /etc/letsencrypt/live/${HOSTNAME}/privkey.pem /config/certs/server-key.pem"  >>  /etc/letsencrypt/renewal-hooks/post/run.sh
        echo "pkill -HUP ocserv" >> /etc/letsencrypt/renewal-hooks/post/run.sh && chmod +x /etc/letsencrypt/renewal-hooks/post/run.sh
else
	#certs already in place
	echo "$(date) [info] Using existing certificates in /config/certs"
fi

# Enable NAT forwarding
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# Create (if required) and enable TUN device
[[ -d /dev/net ]] || mkdir -p /dev/net
[[ -f /dev/net/tun ]] || mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# Can we fix this chmod?
chmod -R 777 /config

# Run OpenConnect Server
exec "$@"
