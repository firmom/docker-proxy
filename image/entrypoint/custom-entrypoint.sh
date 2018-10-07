#!/bin/bash
set -e

# prepare config
cat > /etc/nginx/sites-enabled/default << EndOfConfig
# Nginx Proxy config

EndOfConfig


for i in `env | grep -E "^PROXY_.*_FROM"`; do
    proxyBaseKey="PROXY_$(echo $i| cut -d'_' -f 2)_"
    eval FROM=\${${proxyBaseKey}FROM}
    eval TO=\${${proxyBaseKey}TO}
    eval PORT=\${${proxyBaseKey}PORT}
    echo "PROXY: https://$FORM -> https://$TO:$PORT"
cat >> /etc/nginx/sites-enabled/default << EndOfConfig

server {
  listen 80;
  server_name $FORM www.$FORM;
  return 301 https://\$host\$request_uri;
}

server {
  listen 443;
  server_name $FORM;

  ssl_certificate           /certs/$TO/fullchain.pem;
  ssl_certificate_key       /certs/$TO/fullchain.pem;

  ssl on;
  ssl_session_cache  builtin:1000  shared:SSL:10m;
  ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
  ssl_prefer_server_ciphers on;

  access_log  /dev/stdout;
  error_log   /dev/stderr error;

  location / {
    proxy_set_header        Host \$host;
    proxy_set_header        X-Real-IP \$remote_addr;
    proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header        X-Forwarded-Proto \$scheme;

    # Fix the “It appears that your reverse proxy set up is broken" error.
    proxy_pass          https://$TO:$PORT;
    proxy_read_timeout  90;
    proxy_redirect default;
  }
}
EndOfConfig
done

# run nginx proxy
nginx -g daemon off;
