![Basebuntu](http://i.imgur.com/tbKJAol.png)
--

![License Status](https://img.shields.io/badge/language-bash-blue.svg?style=flat)
![License Status](http://img.shields.io/badge/license-MIT-red.svg?style=flat)

This script is specifically designed for budget boxes running the latest version of Ubuntu Server LTS (currently 14.04). This will run great on a Linode 1GB VPS or Digital Ocean 512MB VPS.

## Purpose

Remove excess packages and install the basic components needed for a light-weight HTTP(S) web server:

 - Nginx (web server with https/SPDY support)
 - PHP-FPM (alternative to mod_php)
 - UFW (firewall)
 - MariaDB (database)
 - Pagespeed (Ngnix module for reducing page load time)
 - Commands for easy administration
 - Custom Nginx commands for working with website configs
 - And more!

## Install

Warning! This script will overwrite previous configs during re-installation. While I have included some checks to prevent overwriting, be aware that things may break if you run a main option command more than once on a box.

	apt-get update; apt-get install git -y; git clone https://github.com/marshallford/basebuntu
	cd ~/basebuntu; chmod +x basebuntu.sh

## Main options

**Note: You must run setup before any other command. Setup installs/configures a base install.**

	./basebuntu.sh setup
	./basebuntu.sh ufw [ssh port]
	./basebuntu.sh www
	./basebuntu.sh mariadb

## Extra options and other commands

##### Harden openSSH

Hardens openSSH with PermitRoot and PasswordAuthentication

	./basebuntu.sh harden-ssh [option #]

1. All users including root can only login via SSH-keys.

2. Normal users can login via SSH-keys, root can't login at all.

3. Root can't login, normal users can use SSH-keys or plain passwords.

4. Normal users can login with SSH-keys or plain passwords, root can only login via SSH-keys.

##### Fail2ban (bruteforce/DOS firewall)

Installs a firewall to protect against bruteforce attacks on ssh and http(s) ports.

	./basebuntu.sh fail2ban

##### Info on Operating System, version and Architecture

	./basebuntu.sh info

##### External IP

To get the server's external IP address.

	./basebuntu.sh ip

##### Updater

Runs a full update and upgrade of packages and then cleans up. This command will not upgrade to a newer release cycles. Ex: 12.04 LTS > 12.10.

	./basebuntu.sh updater

##### basebuntu Updater

Updates basebuntu script and keeps current config file.

	./basebuntu.sh update-bb

##### Fixing locale on some OpenVZ Ubuntu templates

	./basebuntu.sh locale

##### Classic Disk I/O and Network test

Run the classic Disk IO (dd) & Classic Network (cachefly) Test

	./basebuntu.sh test

## Nginx commands

##### Restart

Restarts PHP-FPM and Nginx

	./basebuntu.sh restart

##### Permissions

Sets the proper permissions for `/sites`. This sets the owner and group to the user `deploy`. This allows the deployment user to push websites to the server.

	./basebuntu.sh permissions

To set the owner and group of `/sites` to someone other than `deploy` use the permissions command followed by the name of the user.

	./basebuntu.sh www-permissions user_name_here

##### Add Website

Create folder structure and empty site config for a new website.

	./basebuntu.sh add-site [website name]

##### Remove Website

Deletes website config and files.

	./basebuntu.sh remove-site [website name]

##### Enable Website

Enables/activates website.

	./basebuntu.sh enable-site [website name]

##### Disable Website

Disables/Deactivates website.

	./basebuntu.sh disable-site [website name]

##### Edit Website

Opens website config in nano.

	./basebuntu.sh edit-site [website name]

##### Edit Nginx Config

Opens Nginx config in nano.

	./basebuntu.sh nginx-config

## After installation

- Use `ufw status` to get information on your firewall status
- Run `htop` to see RAM and CPU usage
- Reboot to test that everything is working ok after a boot cycle
- To enable Pagespeed on a virtualhost, include `/etc/ngnix/pagespeed.conf`
- To enable PHP-FPM on a virtualhost, include `/etc/ngnix/enable-php.conf`

## Credits

#### Orginal

- [LowEndBox admin (LEA)](https://github.com/lowendbox/lowendscript)
- [Xeoncross](https://github.com/Xeoncross/lowendscript)
- [ilevkov](https://github.com/ilevkov/lowendscript)
- [asimzeeshan](https://github.com/asimzeeshan)

#### Additional Credits from LET

- [mun](http://lowendtalk.com/profile/7133/Mun)
- [mpkossen](http://lowendtalk.com/profile/3071/mpkossen)
- [jack](http://lowendtalk.com/profile/522/Jack)
- [emg](http://lowendtalk.com/profile/13220/emg)
- [azizmb](http://lowendtalk.com/profile/3240/azizmb)

#### Great Companies/People

- [Delta/Fran](http://buyvm.net)
- [The_Hatta](http://wiki.frantech.ca/doku.php/irc:main)
- [DigitalOcean](http://digitalocean.com)

#### People that have helped along the way

- [vt0r/Salvatore LaMendola](https://github.com/jogfsovt/)
