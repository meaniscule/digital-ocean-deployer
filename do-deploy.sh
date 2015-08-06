#!/bin/bash
echo "Hi! Let's make a new site!"
echo "The next two prompts will ask for 1) subdomain and 2) domain."
echo "Example:"
echo "1. dog"
echo "2. pet.com"
echo "Makes dog.pet.com"
echo "Lastly, you'll provide the server port to listen on and a name for your app."
echo ""
echo "Let's make magic happen!"
echo ""

echo "Please enter your subdomain, e.g. dog"
read SUBDOMAIN
echo "Ok, subdomain is $SUBDOMAIN."
echo ""

echo "Please enter your domain, e.g. pet.com"
read DOMAIN
echo "Ok, domain is $DOMAIN."
echo ""

echo "Please enter your port"
read PORT
echo "Ok, port $PORT on $SUBDOMAIN for user $USERNAME."
echo ""

echo "What would you like to name the app's directory?"
read APPDIR
echo "We'll put the app in $APPDIR"
echo ""

cd ~/../../etc/nginx/sites-available/

sudo cat >> default << EOM

server {
  listen 80;
  server_name "$SUBDOMAIN.$DOMAIN";
  location / {
    proxy_set_header   X-Real-IP \$remote_addr;
    proxy_set_header   Host      \$http_host;
    proxy_pass         http://127.0.0.1:$PORT;
  }
}
EOM

echo "Your NGINX server was added:"
echo "$(<default)"
echo ""

nginx -s reload
if [ $? != 0 ]
then
	echo "NGINX couldn't be reloaded. Check your permissions or try executing this script with sudo."
	exit 1
else
	echo "NGINX has been reloaded."
	echo ""
fi

cd ~
if [ -d $SUBDOMAIN ]
then
	echo "The folder already exits. Exiting to prevent overwrite. Please try again."
	exit 1
fi

mkdir -pv $SUBDOMAIN/live
mkdir -pv $SUBDOMAIN/repo/site.git
echo ""
cd $SUBDOMAIN/repo/site.git && git init --bare
echo ""

cd hooks
cat > post-receive << EOM
#!/bin/sh
git --work-tree=/home/$(logname)/$SUBDOMAIN/live --git-dir=/home/$(logname)/$SUBDOMAIN/repo/site.git checkout -f
cd ~/$SUBDOMAIN/live
npm install
gulp build

pm2 describe $SUBDOMAIN
if [ \$? != 0 ]
then
        pm2 start server/start.js -i 0 --name $SUBDOMAIN
else
        pm2 restart $SUBDOMAIN
fi
EOM

IPADDR=$(ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)

echo "Git post-receive hook created:"
echo "$(<post-receive)"
echo ""

echo "Your server is all set up!"
echo ""

echo "Now go to your local repo and enter the following lines:"
echo "git remote add live ssh://$(logname)@$IPADDR/home/$(logname)/$SUBDOMAIN/repo/site.git"
echo "git push live master"
