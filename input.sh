#!/bin/bash

echo Please enter your subdomain
read SUBDOMAIN
echo "Ok, subdomain is $SUBDOMAIN."

echo Please enter your port
read PORT
echo "Ok, port $PORT on $SUBDOMAIN for user $USERNAME."

cat >> sample << EOM

server {
  listen 80;
  server_name $SUBDOMAIN;
  location / {
    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   Host      $http_host;
    proxy_pass         http://127.0.0.1:$PORT;
  }
}
EOM

echo "$(<sample)"
