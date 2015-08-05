#!/bin/bash

echo Please enter your subdomain
read SUBDOMAIN
echo "Ok, subdomain is $SUBDOMAIN."

echo Please enter your port
read PORT
echo "Ok, port $PORT on $SUBDOMAIN for user $USERNAME."

cd ~/../../etc/nginx/sites-available/

sudo cat >> default << EOM

server {
  listen 80;
  server_name $SUBDOMAIN;
  location / {
    proxy_set_header   X-Real-IP \$remote_addr;
    proxy_set_header   Host      \$http_host;
    proxy_pass         http://127.0.0.1:$PORT;
  }
}
EOM

echo "Your NGINX server was added:"
echo "$(<default)"

nginx -s reload
if [ $? != 0 ]
then
	echo "NGINX couldn't be reloaded. Check your permissions or try executing this script with sudo."
	exit 1
else
	echo "NGINX has been reloaded."
fi

cd ~
if [ -d $SUBDOMAIN ]
then
	echo "The folder already exits. Exiting to prevent overwrite. Please try again."
	exit 1
else
	mkdir $SUBDOMAIN
fi
