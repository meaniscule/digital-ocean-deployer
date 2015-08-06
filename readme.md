# Subdomain site

This script aims to help site creation on your server via ssh a bit easier.

## Requirements
- Ubuntu 14.04 or higher (might work on older versions, but it hasn't be tested)
- [nginx](http://nginx.org/en/)
- [pm2](https://github.com/Unitech/pm2)

You will also probably need `sudo` privileges.

## Assumptions
The script assumes that:
- you are running the script from somewhere within `/home/user`
- your `nginx` file is titled `default` and exists at `/root/etc/nginx/sites-available`
 
## Installation and execution
Install the script on your server. One way to do this is to `git clone` it into your user directory, for example in `/home/user/bin`.

To make the script executable, `cd` down in to the directory containin the script and enter:
```
chmod +x subdomain-site.sh
```

Now you can run the script by typing in:
```
sudo ./subdomain-site.sh
```

Because the script modifies the nginx file, `sudo` will be required in most cases.

## User input
The script will ask the user for 3 things:
- subdomain
- domain
- port

For example:
```
dog
pet.com
4545
```
This makes a new nginx server with a URL of `dog.pet.com` listening on port `4545`.

## Results
The script does the following:
- adds a new nginx server listening on the specified port and reloads nginx
```
server {
  listen 80;
  server_name "dog.pet.com";
  location / {
    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   Host      $http_host;
    proxy_pass         http://127.0.0.1:1234;
  }
}
```

- makes a new tree 
```
/home/ash/dog
├── live
└── repo
    └── site.git
        ├── branches
        ├── config
        ├── description
        ├── HEAD
        ├── hooks
        │   ├── applypatch-msg.sample
        │   ├── commit-msg.sample
        │   ├── post-receive
        │   ├── post-update.sample
        │   ├── pre-applypatch.sample
        │   ├── pre-commit.sample
        │   ├── prepare-commit-msg.sample
        │   ├── pre-push.sample
        │   ├── pre-rebase.sample
        │   └── update.sample
        ├── info
        │   └── exclude
        ├── objects
        │   ├── info
        │   └── pack
        └── refs
            ├── heads
            └── tags
```

- adds a `post-receive` hook for git

- tells you how to set this repo as a remote for your local repo

## The post-receive hook
Here is the default `post-receive` hook that this script will make:
```
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
```

Note that anything with a `$` is actually going to be replaced with a usable value.

So, after running `git push live master` from your local repo, the `post-receive` script will:
- configure your git work tree and repo
- install npm modules
- run a gulp build process
- either restart pm2 for the site or create a pm2 process for the site if one doesn't already exist
