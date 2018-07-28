#!/bin/bash
unset IFS
set -eo pipefail
shopt -s nullglob

# Compatibility setting
if [ ! -z "$TZ" ]; then
	TIMEZONE="$TZ"
fi

# Set the containers timezone
if [ ! -z "$TIMEZONE" ] && [ -e "/usr/share/zoneinfo/$TIMEZONE" ]; then
	ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
fi

# Reload HAProxy when config changes
if [ ! -z "$HAPROXY_INCROND" ]; then
	echo "/etc/haproxy IN_MODIFY,IN_NO_LOOP flock -F -x -w1 -E0 /tmp/.haproxy-reload systemctl reload haproxy" >/etc/incron.d/haproxy
	systemctl enable incrond
fi

# Reload HAProxy when certificate or OCSP information changes
if [ ! -z "$HAPROXY_LETSENCRYPT_INCROND" ]; then
	echo "/etc/letsencrypt/live/*/fullkeychain.pem IN_MODIFY,IN_NO_LOOP flock -F -x -w1 -E0 /tmp/.haproxy-reload systemctl reload haproxy" >/etc/incron.d/letsencrypt
	echo "/etc/letsencrypt/live/*/fullkeychain.pem.ocsp IN_MODIFY,IN_NO_LOOP flock -F -x -w1 -E0 /tmp/.haproxy-reload systemctl reload haproxy" >/etc/incron.d/letsencrypt-ocsp
	systemctl enable incrond
fi

# Activate yum updates when env variable is set of self updates
if [ ! -z "$SELFUPDATE" ]; then
	sed -i 's/apply_updates = no/apply_updates = yes/g' /etc/yum/yum-cron.conf
	systemctl enable yum-cron
fi

# Issue certificates for given domains if no certificate already exists
if [ ! -z "$HAPROXY_LETSENCRYPT" ]; then
	domains=()
	for var in $(compgen -e); do
	        if [[ "$var" =~ LETSENCRYPT_DOMAIN_.* ]]; then
       		        domains+=( "${!var}" )
	        fi
	done
	for entry in "${domains[@]}"; do
       		array=(${entry//,/ })
		if [ ! -e "/etc/letsencrypt/live/${array[0]}/fullkeychain.pem" ]; then
	       		/usr/local/sbin/certbot-issue ${array[@]}
		fi
	done
fi

exec "$@"
