# www-ubuntu

This script is specifically designed for budget boxes running the latest version of Ubuntu Server LTS (currently 14.04). This will run great on a Linode 1GB VPS or Digital Ocean 512MB VPS.

## Purpose

Remove excess packages and install the basic components needed for a light-weight HTTP(S) web server:

 - Nginx (web server with https/SPDY support)
 - PHP-FPM (alternative to mod_php)
 - UFW (firewall)
 - MariaDB (database)
 - Pagespeed (Ngnix module for reducing page load time)
 - Custom commands for easy administration

## Main options (in recommended order)

**Warning! This script will overwrite previous configs during re-installation.**

	cd ~; wget --no-check-certificate https://raw.github.com/marshallford/lowendubuntu/master/setup-ubuntu.sh; chmod +x setup-ubuntu.sh

	./www-ubuntu.sh setup
	./www-ubuntu.sh firewall [port]
	./www-ubuntu.sh www
	./www-ubuntu.sh mariadb

## Other Commands

##### WWW Permissions

Sets the proper permissions for `/sites`. This sets the owner and group to the user `deploy`. This allows the deployment user to push websites to the server.

	./www-ubuntu.sh www-permissions

To set the owner and group of `/sites` to someone other than `deploy` use the permissions command followed by the name of the user.

	./www-ubuntu.sh www-permissions user_name_here

##### External IP

To get the server's external IP address.

	./www-ubuntu.sh ip

##### Harden openSSH

Hardens openSSH with PermitRoot and PasswordAuthentication

	./www-ubuntu.sh harden-ssh [option #]

1 = All users including root can only login via SSH-keys.

2 = Normal users can login via SSH-keys, root can't login at all.

3 = Root can't login, normal users can use SSH-keys or plain passwords.

4 = Normal users can login with SSH-keys or plain passwords, root can only login via SSH-keys.

##### Fail2ban (bruteforce/Dos firewall)

Installs a firewall to protect against bruteforce attacks on ssh and http(s) ports.

	./www-ubuntu.sh fail2ban

##### Classic Disk I/O and Network test

Run the classic Disk IO (dd) & Classic Network (cachefly) Test

	./www-ubuntu.sh test

##### Updater

Runs a full update and upgrade of packages and then cleans up. This command will not upgrade to a newer release cycles. Ex: 12.04 LTS > 12.10.

	./www-ubuntu.sh updater

##### Info on Operating System, version and Architecture

	./www-ubuntu.sh info

##### Fixing locale on some OpenVZ Ubuntu templates

	./www-ubuntu.sh locale

## After installation

- Use `ufw status` to get information on your firewall status.
- Run `htop` to see RAM and CPU usage
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
