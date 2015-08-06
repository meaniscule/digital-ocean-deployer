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
- adds a new nginx server listening on the specified port
- makes a new tree 
