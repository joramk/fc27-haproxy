# Fedora 27 HAProxy docker image with Let´s Encrypt [![Build Status](https://travis-ci.org/joramk/fc27-haproxy.svg?branch=master)](https://travis-ci.org/joramk/fc27-haproxy)
A Fedora 27 based HAProxy docker image with Let´s Encrypt support in different version flavours.

## Tags
Tag | Description
---|---
*latest* | *Installs HAProxy v1.8.4 (rawhide)*
1.8.4 | Installs HAProxy v1.8.4 (rawhide)

## Features
* Daily automatic self update through the Fedora package management
* Latest Fedora 27 base system with full systemd support and docker instance health check
* Integrated LetsEncrypt Certbot with automatic certificate issueing, updating and OCSP stapling
* Automatic reloading with incrond monitoring for configuration and certifcate changes

## Configuration
Generated LetsEncrypt certifcate files are created by the `certbot-combine` script and stored in `/etc/letsencrypt/live/*/fullkeychain.pem`. You have to include them manually in your `haproxy.cfg` file.

### Environment variables
Variable | Description
---|---
TZ | Sets the container timezone, i.e. `-e "TZ=Europe/Berlin"` _string_
SELFUPDATE | Activates the Fedora base system package selfupdate _boolean_
HAPROXY_INCROND | Monitors /etc/haproxy for changes and reloads HAProxy _boolean_
HAPROXY_DAILY_RELOAD | Reloads the HAProxy configuration every day without tracking changes _boolean_
HAPROXY_LETSENCRYPT | Activates the LetsEncrypt components and installs the renewal cronjob _boolean_
HAPROXY_LETSENCRYPT_OCSP | Activates OCSP stapling and the daily update cronjob _boolean_
HAPROXY_LETSENCRYPT_INCROND | Additional check for LetsEncrypt certificate changes which needs reloading HAProxy _boolean_
LETSENCRYPT\_DOMAIN\_\* | Issues a certificate from LetsEncrypt, i.e. `-e "LETSENCRYPT_DOMAIN_1=www.example.org,mail@example.org"`

### Required haproxy.cfg
The following configuration options are required for the LetsEncrypt scripts and OCSP cronjob.
~~~
global
    stats socket /var/run/haproxy.admin level admin

frontend unsecured
    acl         acme_redirect path_beg -i /.well-known/acme-challenge/
    use_backend certbot if acme_redirect

backend certbot
    server standalone 127.0.0.1:8888
    retries 8
~~~

## First run examples
You can start a container in several ways. You should have a persistent read-only volume for `/etc/haproxy` and a persistent writable volume for `/etc/letsencrypt` when using LetsEncrypt certificates. Here are some examples including my personal run configuration.

### Docker run - Quickstart
~~~
docker run joramk/fc27-haproxy:latest
~~~

### Docker run
~~~
docker run -d -p 80:80 -p 443:443 \
    --tmpfs /run --tmpfs /tmp \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -e "TIMEZONE=Europe/Berlin" \
    joramk/fc27-haproxy:latest
~~~

### Docker run with persistent volumes
~~~
docker run -d -p 80:80 -p 443:443 \
    --tmpfs /run --tmpfs /tmp \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -v /etc/haproxy:/etc/haproxy:ro \
    -v /etc/letsencrypt:/etc/letsencrypt \
    -e "TIMEZONE=Europe/Berlin" \
    joramk/fc27-haproxy:latest
~~~

### Docker run with all options enabled
~~~
docker run -d -p 80:80 -p 443:443 \
    --tmpfs /run --tmpfs /tmp \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -e "TIMEZONE=Europe/Berlin" \
    -e "SELFUPDATE=1" \
    -e "HAPROXY_LETSENCRYPT=1" \
    -e "HAPROXY_LETSENCRYPT_OCSP=1" \
    -e "LETSENCRYPT_DOMAIN_1=www.example.org,someone@example.org"
    -e "LETSENCRYPT_DOMAIN_2=www.example.com,anyone@example.com"
    joramk/fc27-haproxy:latest
~~~

### Docker swarm
~~~
docker service create -d --log-driver=journald -p 80:80 -p 443:443 --replicas 2 \
    --mount type=tmpfs,dst=/run --mount type=tmpfs,dst=/tmp \
    --mount type=bind,src=/sys/fs/cgroup,dst=/sys/fs/cgroup,ro \
    -e "TIMEZONE=Europe/Berlin" \
    -e "SELFUPDATE=1" \
    -e "HAPROXY_LETSENCRYPT=1" \
    -e "HAPROXY_LETSENCRYPT_OCSP=1" \
    -e "LETSENCRYPT_DOMAIN_1=www.example.org,someone@example.org"
    -e "LETSENCRYPT_DOMAIN_2=www.example.com,anyone@example.com"
    joramk/fc27-haproxy:latest
~~~

### Docker run - My personal configuration
~~~
docker run -d \
    --tmpfs /run --tmpfs /tmp \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -v /etc/docker/letsencrypt:/etc/letsencrypt:Z \
    -v /etc/docker/haproxy:/etc/haproxy:Z \
    --network web --ip 172.18.0.2 --hostname=proxy1.docker1.dmz.lonet.org \
    --name proxy1_c --network-alias proxy1.docker1.dmz.lonet.org \
    --dns-search docker1.dmz.lonet.org --dns-search dmz.lonet.org \
    --network-alias jira.lonet.org --network-alias confluence.lonet.org \
    --network-alias git.lonet.org --network-alias lonet.org \
    --network-alias www.lonet.org \
    -e "TIMEZONE=Europe/Berlin" \
    -e "SELFUPDATE=1" \
    -e "HAPROXY_LETSENCRYPT=1" \
    -e "HAPROXY_LETSENCRYPT_OCSP=1" \
    -e "LETSENCRYPT_DOMAIN_1=jira.lonet.org,joramk@gmail.com"
    -e "LETSENCRYPT_DOMAIN_2=confluence.lonet.org,joramk@gmail.com"
    -e "LETSENCRYPT_DOMAIN_3=git.lonet.org,joramk@gmail.com"
    joramk/fc27-haproxy:latest
~~~

## Issue or update certificates manually
~~~
docker exec -ti <container> certbot-issue <domain.tld> <email>
docker exec -ti <container> certbot-renew
~~~
## docker ps on successful start

    CONTAINER ID        IMAGE                        COMMAND                  CREATED             STATUS                    PORTS               NAMES
    c2c6dc6cd27f        joramk/fc27-haproxy:latest   "/docker-entrypoin..."   31 seconds ago      Up 30 seconds (healthy)   80/tcp, 443/tcp     fc27_haproxy

## Found a bug?
Please report issues on GitHub: https://github.com/joramk/fc27-haproxy/issues
