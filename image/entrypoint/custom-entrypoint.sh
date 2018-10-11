#!/bin/bash
set -e

# prepare config
cat > /etc/nginx/conf.d/default.conf << EndOfConfig
# Nginx Proxy config
access_log  /dev/stdout;
error_log   /dev/stderr error;

proxy_set_header Host \$host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto \$scheme;
proxy_set_header X-Forwarded-Host \$server_name;

server {
  listen 80;
  return 301 https://\$host\$request_uri;
}
EndOfConfig

for i in `env | grep -E "^PROXY_.*_FROM"`; do
    proxyBaseKey="PROXY_$(echo $i| cut -d'_' -f 2)_"
    eval FROM=\${${proxyBaseKey}FROM}
    eval CERT=\${${proxyBaseKey}CERT}
    eval TO=\${${proxyBaseKey}TO}
    eval PORT=\${${proxyBaseKey}PORT}
    echo "PROXY: https://$FROM -> https://$TO:$PORT"
cat >> /etc/nginx/conf.d/default.conf << EndOfConfig

upstream docker-$TO-$PORT {
  server $TO:$PORT;
}

server {
  listen 443 ssl;
  server_name $FROM www.$FROM;

  ssl_certificate      /certs/$CERT/fullchain.pem;
  ssl_certificate_key  /certs/$CERT/privkey.pem;

  ssl_session_cache  builtin:1000  shared:SSL:10m;
  ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
  ssl_prefer_server_ciphers on;

  access_log  /dev/stdout;
  error_log   /dev/stderr error;

  location / {
    proxy_pass          https://docker-$TO-$PORT;
    proxy_read_timeout  90;
    proxy_ssl_verify    off;
    proxy_redirect      off;
  }
}
EndOfConfig
done

# run nginx proxy
nginx -g "daemon off;"
