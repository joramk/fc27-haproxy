#!/bin/bash
unset IFS
set -eo pipefail
shopt -s nullglob

setup() {
        if [ ! -z "$SELFUPDATE" ]; then
		sed -i 's/apply_updates = no/apply_updates = yes/g' /etc/yum/yum-cron.conf
                systemctl enable yum-cron
                yum update -y
        fi

	if [ ! -z "$TZ" ]; then
		TIMEZONE="$TZ"
	fi

        if [ ! -z "$TIMEZONE" ] && [ -e "/usr/share/zoneinfo/$TIMEZONE" ]; then
                ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
        fi

	if [ ! -z "$HAPROXY_LETSENCRYPT" ]; then
		domains=()
		for var in $(compgen -e); do
		        if [[ "$var" =~ LETSENCRYPT_DOMAIN_.* ]]; then
        		        domains+=( "${!var}" )
		        fi
		done
		for entry in "${domains[@]}"; do
        		array=(${entry//,/ })
        		/usr/local/sbin/certbot-issue ${array[@]}
		done
        fi	
}

if [ -e /firstrun ] && [ -z "$OMIT_FIRSTRUN" ]; then      
        setup
fi

rm -f /firstrun

exec "$@"
