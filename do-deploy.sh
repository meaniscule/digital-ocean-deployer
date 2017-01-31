#!/bin/bash

# Dependency checking; nginx and pm2 are required
echo "Just a moment. I'm checking dependencies..."
echo ""

dpkg -l nginx | >/dev/null 
if [ $? != 0 ]
then
	echo "I need to install nginx. Is that ok? Y/n"
	read RESPONSE
	if [ $RESPONSE != "Y" ]
	then
		echo "Aww, I need nginx to work my magic."
		exit 1
	else
		echo "Ok! Installing nginx..."
		apt-get update
		apt-get install nginx
		if [ $? != 0 ]
		then
			echo "Looks like there was a problem with installing nginx."
			exit 1
		else
			echo "nginx successfully installed!"
		fi
	fi
else
	echo ""
	echo "Nice, you've already got nginx!"
fi

echo ""
echo ""

npm list -g pm2
if [ $? != 0 ]
then
        echo "I need to install pm2. Is that ok? Y/n"
        read RESPONSE
        if [ $RESPONSE != "Y" ]
        then
                echo "Aww, I need pm2 to work my magic."
                exit 1
        else
                echo "Ok! Installing pm2..."
                npm install -g pm2
                if [ $? != 0 ]
                then
                        echo "Looks like there was a problem with installing pm2."
                        exit 1
                else
                        echo "pm2 successfully installed!"
                fi
        fi
else
        echo ""
	echo "Nice, you've already got pm2!"
fi

echo ""
echo ""

echo "Ok! Dependencies are in order. Let's make a new site!"
echo "================="
echo ""


# User input variables for setup
echo "Please enter your nginx server_name(s)"
echo "(Space-separated, e.g.: example.org  www.example.org.)"
read SERVERNAME
echo "Ok, subdomain is $SERVERNAME."
echo ""

echo "Please enter your port"
read PORT
echo "Ok, port $PORT on $SERVERNAME."
echo ""

echo "What would you like to name the app?"
echo "(Used for nginx server filename and git repo dirname.)"
read APPNAME
if [ -f /etc/nginx/sites-available/"$APPNAME" ]
then
	echo "That app nginx file already exits. Exiting to prevent overwrite. Please try again."
	exit 1
else
	echo "Creating the nginx server file for ${APPNAME}"
	echo ""
fi


# Set up nginx and restart
cd /etc/nginx/sites-available
touch $APPNAME
chown -R $(logname):$(logname) $APPNAME

sudo cat >> $APPNAME << EOM
server {
	listen 80;
	server_name $SERVERNAME;

	location / {		
		proxy_pass http://127.0.0.1:$PORT;
	}
}
EOM

cd /etc/nginx
ln -s /etc/nginx/sites-available/"$APPNAME" /etc/nginx/sites-enabled/
cd /etc/nginx/sites-available

echo "Your nginx server was added to nginx sites-available and sites-enabled:"
echo "$(<$APPNAME)"
echo ""

service nginx restart
if [ $? != 0 ]
then
	echo "nginx couldn't be reloaded. Check your permissions or try executing this script with sudo."
	exit 1
else
	echo "nginx has been reloaded."
	echo ""
fi


# Make the dir for the repo; set up git and git post-receive
cd /var/www
mkdir -pv $APPNAME/live
mkdir -pv $APPNAME/repo/site.git
echo ""
cd $APPNAME/repo/site.git && git init --bare
echo ""

cd hooks
touch post-receive

cat > post-receive << EOM
#!/bin/sh
git --work-tree=/var/www/$APPNAME/live --git-dir=/var/www/$APPNAME/repo/site.git checkout -f
cd /var/www/$APPNAME/live
npm install
gulp build

pm2 describe $APPNAME
if [ \$? != 0 ]
then
        pm2 start server/start.js -i 0 --name $APPNAME
else
        pm2 restart -f $APPNAME
fi
EOM

chmod a+x post-receive

echo "Git post-receive hook created:"
echo "$(<post-receive)"
echo ""

cd /var/www
chown -R $(logname):$(logname) $APPNAME


# Final instructions for local git setup
echo "Your server is all set up!"
echo ""

IPADDR=$(ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)

echo "Now go to your local repo and enter the following lines:"
echo "git remote add live ssh://$(logname)@$IPADDR/var/www/${APPNAME}/repo/site.git"
echo "git push live master"

exit 0