# LowEndUbuntu

Written for a 512MB/1GB Ubuntu VPS. I realize this isn't exactly "low end", but this script is made for high traffic sites on a budget. Tip: This is perfect for Digital Ocean's $5/month SSD server.

[TO-DO](todo.md)

-- 

Remove excess packages (apache2, sendmail, bind9, samba, nscd, etc) and install the basic components needed for a light-weight HTTP(S) web server:

 - ufw (firewall)
 - dash (replaces bash)
 - syslogd
 - MySQL (v5.5+)
 - PHP-FPM (v5.3+ with APC installed and configured)
 - nginx (v1.2+ from dotdeb, configured for lowend VPS. Change worker_processes in nginx.conf according to number of CPUs)
 - git, vim, nano, mc, htop, iftop & iotop

Includes sample nginx config files for PHP sites. You can create a basic site shell (complete with nginx vhost) like this:

	./setup-ubuntu.sh site example.com

Also includes a basic WordPress setup function, just remember to setup and connect a database afterwords.

	./setup-ubuntu.sh wordpress example.com	

When running the UFW command you must specify a SSH port. Remember, port 22 is the default. It's recommended that you change this from 22 just to save server load from attacks on that port.

## Usage (in recommended order)

### Warning! This script will overwrite previous configs during reinstallation.

	cd ~; wget --no-check-certificate https://raw.github.com/marshallford/lowendubuntu/master/setup-ubuntu.sh; chmod +x setup-ubuntu.sh
	
	./setup-ubuntu.sh system
	./setup-ubuntu.sh ufw [port]
	./setup-ubuntu.sh mysql
	./setup-ubuntu.sh nginx
	./setup-ubuntu.sh php
	./setup-ubuntu.sh site [domain.tld]
	./setup-ubuntu.sh wordpress [domain.tld]

#### ... and now time for some extras

##### Harden openSSH

Hardens openSSH with PermitRoot and PasswordAuthentication

	./setup-ubuntu.sh harden_ssh [option #]

1 = All users including root can only login via SSH-keys.

2 = Normal users can login via SSH-keys, root can't login at all.

3 = Root can't login, normal users can use SSH-keys or plain passwords.

4 = Normal users can login with SSH-keys or plain passwords, root can only login via SSH-keys.

##### vzfree

Supported only on OpenVZ only, vzfree reports correct memory usage

	./setup-ubuntu.sh vzfree

##### Classic Disk I/O and Network test

Run the classic Disk IO (dd) & Classic Network (cachefly) Test

	./setup-ubuntu.sh test

##### Neat python script to report memory usage per app

Neat python script to report memory usage per app

	./setup-ubuntu.sh ps_mem

##### sources.list updating

Updates Ubuntu /etc/apt/sources.list to default based on whatever version you are running

	./setup-ubuntu.sh apt

##### Info on Operating System, version and Architecture

	./setup-ubuntu.sh info
    
##### Extras

Fixing locale on some OpenVZ Ubuntu templates

	./setup-ubuntu.sh locale

Configure or reconfigure MOTD

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
- [Xeoncross](https://github.com/Xeoncross/lowendscript),
- [ilevkov](https://github.com/ilevkov/lowendscript),
- [asimzeeshan](https://github.com/asimzeeshan)

#### Additional Credits from LET

- [mun](http://lowendtalk.com/profile/7133/Mun)
- [mpkossen](http://lowendtalk.com/profile/3071/mpkossen)
- [jack](http://lowendtalk.com/profile/522/Jack)
- [emg](http://lowendtalk.com/profile/13220/emg)
- [azizmb](http://lowendtalk.com/profile/3240/azizmb)

#### Great Hosts/People

- [Delta/Fran](http://buyvm.net)
- [The_Hatta](irc://irc.frantech.ca)
- [DigitalOcean](http://digitalocean.com)
