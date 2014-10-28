# www-ubuntu

This script is specifically designed for budget boxes running the latest version of Ubuntu Server LTS (currently 14.04). This will run great on a Linode 1GB VPS or Digital Ocean 512MB VPS.

## Purpose

Remove excess packages (apache2, sendmail, bind9, samba, nscd, etc) and install the basic components needed for a light-weight HTTP(S) web server:

 - Ufw (firewall)
 - MariaDB (database)
 - PHP-FPM (alternative to mod_php)
 - Nginx (web server with https/SPDY support)
 - Pagespeed (Ngnix module for reducing page load time)
 - Git (verion control, latest build installed)
 - Fail2ban (dynamic protection framework)
 - Other tools required for running a web server
 - Custom commands for easy administration

## Usage (in recommended order)

### Warning! This script will overwrite previous configs during re-installation.

	cd ~; wget --no-check-certificate https://raw.github.com/marshallford/lowendubuntu/master/setup-ubuntu.sh; chmod +x setup-ubuntu.sh

	./setup-ubuntu.sh system
	./setup-ubuntu.sh ufw [port]
	./setup-ubuntu.sh mariadb
	./setup-ubuntu.sh nginx
	./setup-ubuntu.sh php

### After the minimal usage, create websites with the following commands...

The lowendubuntu scipt includes a sample nginx config files for PHP sites. You can create a basic site shell (complete with nginx vhost) like this:

	./setup-ubuntu.sh site example-domain.tld

The script also includes a basic WordPress setup function, just remember to setup and connect a database afterwords.

	./setup-ubuntu.sh wordpress example-domain.tld

## Extra Commands

##### WWW Permissions

Sets the proper permissions for `/var/www`. This includes setting the owner and group to www-data and giving group members of www-data rwx permssions. This allows a deployment user that is a member of www-data to push websites to the server.

	./setup-ubuntu.sh permissions

To set the owner and group of `/var/www` to something other than www-data use the permissions command followed by the name of the user.

	./setup-ubuntu.sh permissions user_name_here

##### External IP

To get the server's external IP address.

	./setup-ubuntu.sh ip

##### Harden openSSH

Hardens openSSH with PermitRoot and PasswordAuthentication

	./setup-ubuntu.sh harden_ssh [option #]

1 = All users including root can only login via SSH-keys.

2 = Normal users can login via SSH-keys, root can't login at all.

3 = Root can't login, normal users can use SSH-keys or plain passwords.

4 = Normal users can login with SSH-keys or plain passwords, root can only login via SSH-keys.

##### Git based deployment system

Uses git hooks and checkout, supports WordPress installs. ([Script Source](https://github.com/marshallford/gitdeploy))

	./setup-ubuntu.sh gitdeploy [domain.tld]

##### vzfree

Supported only on OpenVZ only, vzfree reports correct memory usage

	./setup-ubuntu.sh vzfree

##### Fail2ban (bruteforce/Dos firewall)

Installs a firewall to protect against bruteforce attacks on ssh and http(s) ports.

	./setup-ubuntu.sh fail2ban

##### Classic Disk I/O and Network test

Run the classic Disk IO (dd) & Classic Network (cachefly) Test

	./setup-ubuntu.sh test

##### Memory Usage Script

Neat python script to report memory usage per app

	./setup-ubuntu.sh ps_mem

##### sources.list updating

Updates Ubuntu /etc/apt/sources.list to default based on whatever version you are running

	./setup-ubuntu.sh apt

##### Super Updater

Runs a full update and upgrade of packages and then cleans up. This command will not upgrade to a newer release cycles. Ex: 12.04 LTS > 12.10.

	./setup-ubuntu.sh super_updater

##### Info on Operating System, version and Architecture

	./setup-ubuntu.sh info

##### Fixing locale on some OpenVZ Ubuntu templates

	./setup-ubuntu.sh locale

##### Configure or reconfigure MOTD

	./setup-ubuntu.sh motd

## After installation

- Use `ufw status` to get information on your firewall status.
- Run `htop` to see RAM and CPU usage
- By default PHP is configured to max at 156MB
- By default APC is configured to use 48MB for caching.
- To reduce ram usage, you may disable APC by moving or deleting the following file - /etc/php5/conf.d/apc.ini
- Reboot to test that everything is working ok after a boot cycle.

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
