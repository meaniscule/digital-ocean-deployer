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
fi

mkdir -pv $SUBDOMAIN/live
mkdir -pv $SUBDOMAIN/repo/site.git
cd $SUBDOMAIN/repo/site.git && git init --bare

cat > post-receive << EOM
#!/bin/sh
git —work-tree=/home/$(logname)/$SUBDOMAIN/live —git-dir=/home/$(logname)/$SUBDOMAIN/repo/site.git checkout -f
cd ~/$SUBDOMAIN/live
npm install
gulp build
pm2 restart $SUBDOMAIN
EOM

echo "Git post-receive hook created:"
echo "$(<post-receive)"
