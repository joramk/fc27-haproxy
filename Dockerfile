FROM    joramk/fc27-base
MAINTAINER joramk@gmail.com
ENV     container docker

LABEL   name="Fedora - HAproxy 1.8 with Lets Encrypt" \
        vendor="https://github.com/joramk/fc27-haproxy" \
        license="none" \
        build-date="20180304" \
        maintainer="joramk" \
	issues="https://github.com/joramk/fc27-haproxy/issues"

RUN {	yum update -y; \
        yum install fedora-repos-rawhide incron openssl certbot cronie procps-ng iputils socat yum-cron -y; \
	yum --nogpg --disablerepo=* --enablerepo=rawhide --releasever=28 install haproxy -y; \
        yum clean all && rm -rf /var/cache/yum; \
}

COPY    docker-entrypoint.sh /
COPY    scripts/certbot-* /usr/local/sbin/
COPY 	haproxy.cron /etc/cron.daily/

RUN {	systemctl enable haproxy crond; \
	systemctl disable auditd; \
	chmod +rx /docker-entrypoint.sh /etc/cron.daily/haproxy.cron; \
	chmod 700 /usr/local/sbin/certbot-*; \
	mkdir -p /etc/letsencrypt/live; \
}

RUN {	yum install -y systemd-devel wget; \
	yum --releasever=29 --enablerepo=rawhide install -y gcc openssl-devel; \
	yum clean all && rm -rf /var/cache/yum; \
	cd /usr/local/src; \
	wget http://www.haproxy.org/download/1.8/src/haproxy-1.8.13.tar.gz; \
	tar xvfz haproxy-1.8.13.tar.gz; \
	cd haproxy-1.8.13; \
	make TARGET=linux2628 CPU=native USE_PCRE2=1 USE_PCRE2_JIT=1 USE_TFO=1 USE_LINUX_TPROXY=1 USE_CRYPT_H=1 USE_GETADDRINFO=1 USE_ZLIB=1 USE_REGPARM=1 USE_OPENSSL=1 USE_SYSTEMD=1; \
	make install; \
	rm -f /etc/systemd/system/multi-user.target.wants/haproxy.service; \
	cp /usr/lib/systemd/system/haproxy.service /etc/systemd/system/; \
	sed -i 's/\/usr\//\/usr\/local\//g' /etc/systemd/system/haproxy.service; \
	systemctl enable haproxy; \
	rm -rf /usr/local/src/haproxy-1.8.13*; \
}

HEALTHCHECK CMD systemctl -q is-active haproxy || exit 1
STOPSIGNAL SIGRTMIN+3
EXPOSE 80 443
VOLUME [ “/sys/fs/cgroup”, "/etc/haproxy", "/etc/letsencrypt" ]
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "/sbin/init" ]
