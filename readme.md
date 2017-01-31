# Meaniscule Digital Ocean Deployer

This script aims to help you deploy your [Meaniscule](https://github.com/meaniscule/meaniscule) site to Digital Ocean with ease and win.

## Contents
- [Requirements](https://github.com/meaniscule/digital-ocean-deployer/blob/master/README.md#requirements)
- [Assumptions](https://github.com/meaniscule/digital-ocean-deployer/blob/master/README.md#assumptions)
- [Installation and execution](https://github.com/meaniscule/digital-ocean-deployer/blob/master/README.md#installation-and-execution)
- [User input](https://github.com/meaniscule/digital-ocean-deployer/blob/master/README.md#user-input)
- [Results](https://github.com/meaniscule/digital-ocean-deployer/blob/master/README.md#results)
  - The nginx server block
  - The tree
  - The post-receive hook
  - The local remote settings

## Requirements
Local
- A *local* git repo containing a [Meaniscule](https://github.com/meaniscule/meaniscule) app

Server
- Ubuntu 14.04 or higher*
- `sudo` privileges
- [nginx](http://nginx.org/en/)**
- [pm2](https://github.com/Unitech/pm2)**

_*Might work on older versions of Ubuntu, but it hasn't been tested_

_**The script will check to see if you have nginx and pm2 installed, and if you don't, it will optionally offer to install them for you._

## Assumptions
The script assumes that:
- you want to deploy the site within your `/var/www` directory
- you want to add your nginx server file `/etc/nginx/sites-available`
- you want to make a symbolic link to your nginx server file in `/etc/nginx/sites-enabled`
 
## Installation and execution
Install the script on your server. One way to do this is to `git clone` it into your user directory.

To make the script executable, `cd` into the directory containing the script and enter:
```
chmod +x do-deploy.sh
```

Now you can run the script by typing in:
```
sudo ./do-deploy.sh
```

`sudo` will be required in most cases.


## User input
The script will ask the user for:
- [nginx server_name](https://nginx.org/en/docs/http/server_names.html)
- port
- app name (used as nginx filename and app directory name)

For example:
```
example.com www.example.com
4545
example.com
```

This makes a new nginx server for `example.com` and `www.example.com` listening on port `4545`, and sets up your app's file tree in `/var/www`.


## Results
The script does the following:
- adds a new nginx server listening on the specified port and reloads nginx
- makes a new tree and initializes a `--bare` git repo 
- adds a `post-receive` hook for git
- tells you how to set this repo as a remote for your local repo


### The nginx server block
```
server {
  listen 80;
  server_name example.com www.example.com;

  location / {
    proxy_pass         http://127.0.0.1:4545;
  }
}
```

### The tree
```
/var/www/example.com
├── live
└── repo
    └── site.git
        ├── branches
        ├── config
        ├── description
        ├── HEAD
        ├── hooks
        │   └── post-receive
        ├── info
        │   └── exclude
        ├── objects
        │   ├── info
        │   └── pack
        └── refs
            ├── heads
            └── tags
```


### The post-receive hook
Here is the default `post-receive` hook that this script will make (using our `dog-site` example):

```
#!/bin/sh
git --work-tree=/var/www/example.com/live --git-dir=/var/www/example.com/repo/site.git checkout -f
cd /var/www/example.com/live
npm install
gulp build

pm2 describe example.com
if [ \$? != 0 ]
then
        pm2 start server/start.js -i 0 --name example.com
else
        pm2 restart example.com
fi
```

In other words, after running `git push live master` from your local repo, the `post-receive` script will:

- configure your git work tree and repo
- install npm modules (if there are new ones to install)
- run a gulp build process then exit gulp
- either restart the pm2 process for the site or create a pm2 process for the site if one doesn't already exist


### The local remote settings
When the Digital Ocean Deployer script is finished running, it will give you these two lines, which are meant to be used in your local repo:
```
git remote add live ssh://ash@SERVER_IP_OR_DOMAIN/var/www/example.com/repo/site.git
git push live master
```

The first line sets your local repo's `live` remote to point to the server's repo (the one that the script just created for you). Enter this first line into your local repo right away.

The second line is what you will use any time you want to deploy to your server: `git push live master`.

*Note:* this `git push` has nothing to do with GitHub or any other remote `origin`. If you are open sourcing on GitHub, you can push to GitHub with `git push origin master` without ever affecting your deployed site. This way you can push to and pull from GitHub until you are ready to deploy. Then when you are ready, you can enter `git push live master` which will deploy your *local* repo directly to your server. 
