#!/bin/bash
currentUbuntuVersionSupported="14.04"

############################################################
# Functions
############################################################

# installer nickName, actualName
# example: installer best-text-editor nano
function installer
{
	if [ -z "`which "$1" 2>/dev/null`" ]
	then
		executable=$1
		shift
		while [ -n "$1" ]
		do
			DEBIAN_FRONTEND=noninteractive apt-get -q -y install "$1"
			apt-get clean
			printInfo "$executable installed"
			shift
		done
	else
		printWarn "$2 already installed"
	fi
}

# uninstaller nickName, actualName
# example: uninstaller /usr/sbin/apache2 'apache2*'
function uninstaller
{
	if [ -n "`which "$1" 2>/dev/null`" ]
	then
		DEBIAN_FRONTEND=noninteractive apt-get -q -y remove --purge "$2"
		apt-get clean
		printInfo "$2 uninstalled"
	else
		printWarn "$2 is not installed"
	fi
}

# exits script if something goes wrong
function die
{
	echo "ERROR: $1" > /dev/null 1>&2
	exit 1
}

# Green Text
function printInfo {
	echo -n -e '\e[32m'
	echo -n $1
	echo -e '\e[0m'
}

# Yellow Text
function printWarn
{
	echo -n -e '\e[93m'
	echo -n $1
	echo -e '\e[0m'
}

# Red Text
function printError
{
	echo -n -e '\e[91m'
	echo -n $1
	echo -e '\e[0m'
}

# Do some sanity checking (root and Ubuntu version)
function checkSanity
{
	if [ $(/usr/bin/id -u) != "0" ]
	then
		die 'Must be run by root user'
	fi
	. /etc/lsb-release
	version=$DISTRIB_RELEASE
	if [ "$version" != "$currentUbuntuVersionSupported" ]
	then
		die "Distribution is not supported"
	fi
}

############################################################
# Initial Setup
############################################################

function baseInstaller
{
	installer nano nano # text editor
	installer vim vim # text editor
	installer iftop iftop # show network usage
	installer nload nload # visualize network usage
	installer htop htop # task manager
	installer mc mc # file explorer
	installer unzip unzip
	installer zip zip
	installer curl curl
	installer screen screen
	installer gt5 gt5 # visual disk usage
	installer nslookup dnsutils # dns tools
	ppaGit # verison control
}

function removeUneededPackages
{
	# Apache
	service apache2 stop
	apt-get remove apache2* -y
	apt-get autoremove -y
}

function setTimezone
{
	dpkg-reconfigure tzdata
}

function ppaSupport
{
	installer python-software-properties python-software-properties
	installer software-properties-common software-properties-common
}

function hardenSysctl
{
	source ~/www-ubuntu/www-ubuntu.conf
	if [ "$hasHardenSysctlRun" = false ]
	then
		cat sysctl-append.conf >> /etc/sysctl.conf
		sysctl -p > /dev/null
		sed -i 's/hasHardenSysctlRun.*/hasHardenSysctlRun=true/' www-ubuntu.conf
	else
		printWarn "hardenSysctl has already been run on this system, function skipped."
	fi
}

function ppaGit
{
	add-apt-repository ppa:git-core/ppa -y
	apt-get update
	apt-get upgrade -y # git was installed to pull in www-ubuntu
	printInfo "git was upgraded to the ppa verison"
}

function scriptAlias
{
	source ~/www-ubuntu/www-ubuntu.conf
	if [ "$hasAnAliasBeenAdded" = false ]
	then
		echo "alias www-ubuntu='/root/www-ubuntu/www-ubuntu.sh'" >> /root/.bashrc
		echo "alias wwwu='/root/www-ubuntu/www-ubuntu.sh'" >> /root/.bashrc
		cd ~/www-ubuntu
		sed -i 's/hasAnAliasBeenAdded.*/hasAnAliasBeenAdded=true/' www-ubuntu.conf
	fi
}

function updateWwwUbuntu
{
	cp ~/www-ubuntu/www-ubuntu.conf ~/www-ubuntu.conf.tmp
	cd ~/www-ubuntu
	git reset --hard HEAD
	git pull
	chmod +x www-ubuntu.sh
	rm www-ubuntu.conf
	mv ~/www-ubuntu.conf.tmp ~/www-ubuntu/www-ubuntu.conf
	printInfo "Updated www-ubuntu successfully"
}

function baseSetup
{
	setTimezone
	removeUneededPackages
	runUpdater
	hardenSysctl
	ppaSupport
	baseInstaller
	runCleaner
	scriptAlias
}

############################################################
# Main options
############################################################

# Nginx/PHP
function installWWW
{
	source ~/www-ubuntu/www-ubuntu.conf
	if [ "$hasInstallWWW" = true ]
	then
		die "installWWW has already been run, if run again conflicts will be created"
	fi
	NGINX="1.6.2"
	PAGESPEED="1.9.32.2"
	PSOL="1.9.32.2"
	WWWUSER="deploy"
	# Create user
	adduser deploy
	# PHP
	# https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mysql-php-lemp-stack-on-ubuntu-14-04
	installer php5-fpm php5-fpm
	installer php5-mysql php5-mysql
	installer php-apc php-apc
	sed -i "s/user = www-data/user = $WWWUSER/" /etc/php5/fpm/pool.d/www.conf
	sed -i "s/group = www-data/group = $WWWUSER/" /etc/php5/fpm/pool.d/www.conf
	sed -i "s/listen.owner = www-data/listen.owner = $WWWUSER/" /etc/php5/fpm/pool.d/www.conf
	sed -i "s/listen.group = www-data/listen.group = $WWWUSER/" /etc/php5/fpm/pool.d/www.conf
	chown $WWWUSER:$WWWUSER /var/run/php5-fpm.sock
	service php5-fpm restart

	# Nginx/Pagespeed from source
	installer build-essential build-essential
	installer zlib1g-dev zlib1g-dev
	installer libpcre3 libpcre3
	installer libpcre3-dev libpcre3-dev
	installer libssl-dev libssl-dev
	cd ~
	wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${PAGESPEED}-beta.zip
	unzip release-${PAGESPEED}-beta.zip
	cd ngx_pagespeed-release-${PAGESPEED}-beta/
	wget https://dl.google.com/dl/page-speed/psol/${PSOL}.tar.gz
	tar -xzvf ${PSOL}.tar.gz  # extracts to psol/
	cd ~
	wget http://nginx.org/download/nginx-$NGINX.tar.gz # download nginx
	tar -xvzf nginx-$NGINX.tar.gz # uncompress nginx
	cd nginx-$NGINX/
	# Below are nginx configure and make commands
	# Things to note:
	# 1. User and group is deploy not www-data
	# 2. Installs needed SSL modules
	# 3. Includes cool gzip stuff
	./configure --sbin-path=/usr/local/sbin --conf-path=/etc/nginx/nginx.conf --user=$WWWUSER --group=$WWWUSER --lock-path=/var/lock/nginx.lock --pid-path=/var/run/nginx.pid --add-module=$HOME/ngx_pagespeed-release-$PAGESPEED-beta --with-http_spdy_module --with-http_ssl_module --with-http_gzip_static_module --with-http_stub_status_module --with-http_realip_module
	make
	make install
	# H5BP
	mkdir ~/temp-h5bp
	cd ~/temp-h5bp
	git clone https://github.com/h5bp/server-configs-nginx.git .
	cp -r ~/temp-h5bp/h5bp /etc/nginx/
	# Load in custom nginx.conf
	rm /etc/nginx/nginx.conf
	cp ~/www-ubuntu/www-conf/nginx.conf /etc/nginx/nginx.conf
	# Load in nginx init script
	cp ~/www-ubuntu/www-conf/nginx-init /etc/init.d/nginx
	chmod +x /etc/init.d/nginx
	/usr/sbin/update-rc.d -f nginx defaults
	# Load in custom pagespeed conf
	cp ~/www-ubuntu/www-conf/pagespeed.conf /etc/nginx/pagespeed.conf
	# Load in h5bp/server-configs-nginx mime.types
	rm /etc/nginx/mime.types
	cp ~/temp-h5bp/mime.types /etc/nginx/mime.types
	# Load in h5bp/server-configs-nginx sites-available example
	cp -R ~/temp-h5bp/sites-available/ /etc/nginx/
	# Make all the needed directories
	mkdir /var/cache/nginx
	mkdir /var/ngx_pagespeed_cache
	mkdir /var/log/nginx
	mkdir /var/log/pagespeed
	# mkdir /etc/nginx/sites-available
	mkdir /etc/nginx/sites-enabled
	mkdir /sites
	# permissions for newly created directories
	chown -R $WWWUSER:$WWWUSER /var/cache/nginx
	chown -R $WWWUSER:$WWWUSER /var/ngx_pagespeed_cache
	chown -R $WWWUSER:$WWWUSER /var/log/nginx
	chown -R $WWWUSER:$WWWUSER /var/log/pagespeed
	chown -R $WWWUSER:$WWWUSER /etc/nginx/sites-available
	chown -R $WWWUSER:$WWWUSER /etc/nginx/sites-enabled
	chown -R $WWWUSER:$WWWUSER /sites
	# clean up
	cd ~
	rm -rf release-${PAGESPEED}-beta.zip nginx-$NGINX.tar.gz nginx-$NGINX ngx_pagespeed-release-${PAGESPEED}-beta temp-h5bp
	# finishing touches
	rm -rf /usr/share/nginx/html # remove default website
	service nginx restart # restarts nginx
	cd ~/www-ubuntu
	sed -i 's/hasInstallWWWRun.*/hasInstallWWWRun=true/' www-ubuntu.conf
}

# MariaDB
function installMariadb
{
	apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
	add-apt-repository 'deb http://mirror.stshosting.co.uk/mariadb/repo/10.0/ubuntu trusty main'
	apt-get update
	installer mariadb-server mariadb-server
	service mysql start
	printInfo "Respond YES to all questions asked to secure your MariaDB install"
	mysql_secure_installation
}

# UFW
function installUfw
{
	if [ -z "$1" ]
	then
		die "Usage: `basename $0` firewall [ssh port]"
	fi
	installer ufw ufw
	# Reconfigure sshd - change port
	sed -i 's/^Port [0-9]*/Port '$1'/' /etc/ssh/sshd_config
    service ssh restart

	ufw disable
	ufw default allow outgoing
	ufw default deny incoming
	ufw allow http
	ufw allow https
	ufw allow $1
	ufw --force enable
	printInfo "UFW Status"
	ufw status
}

############################################################
# Commands
############################################################

# updater
function runUpdater
{
	for i in 1 2
	do
		apt-get -q -y update
		apt-get -q -y upgrade
		apt-get -q -y dist-upgrade
		# clean up
		runCleaner
	done
}

function runCleaner
{
	apt-get -q -y autoremove
	apt-get -q -y autoclean
	apt-get -q -y clean
}

# test
function runTests
{
	printInfo "Classic I/O test"
	printInfo "dd if=/dev/zero of=iotest bs=64k count=16k conv=fdatasync && rm -fr iotest"
	dd if=/dev/zero of=iotest bs=64k count=16k conv=fdatasync && rm -fr iotest

	printInfo "Network test"
	printInfo "wget cachefly.cachefly.net/100mb.test -O 100mb.test && rm -fr 100mb.test"
	wget cachefly.cachefly.net/100mb.test -O 100mb.test && rm -fr 100mb.test
}

# locale
function fixLocale
{
	installer multipath-tools multipath-tools
	export LANGUAGE=en_US.UTF-8
	export LANG=en_US.UTF-8
	export LC_ALL=en_US.UTF-8
	# Generate locale
	locale-gen en_US.UTF-8
	dpkg-reconfigure locales
}

# ip
# script compatible with NATed servers.
function getIp
{
	IP=$(wget -qO- ipv4.icanhazip.com)
	if [ "$IP" = "" ]; then
    	IP=$(ifconfig | grep 'inet addr:' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d: -f2 | awk '{ print $1}')
	fi
	echo $IP
}

# harden-ssh [option #]
function hardenSsh
{
	if [ -z "$1" ]
	then
		die "Usage: `basename $0` harden-ssh [option #]"
	fi
	if [ "$1" == 1 ] # All users including root can only login via SSH-keys.
	then
		sed -i 's/.PermitRootLogin.*/PermitRootLogin without-password/' /etc/ssh/sshd_config
		sed -i 's/.PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
	elif [ "$1" == 2 ] # Normal users can login via SSH-keys, root can't login at all.
	then
		sed -i 's/.PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
		sed -i 's/.PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
	elif [ "$1" == 3 ] # Root can't login, normal users can use SSH-keys or plain passwords.
	then
		sed -i 's/.PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
		sed -i 's/.PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
	elif [ "$1" == 4 ] # Normal users can login with SSH-keys or plain passwords, root can only login via SSH-keys.
	then
		sed -i 's/.PermitRootLogin.*/PermitRootLogin without-password/' /etc/ssh/sshd_config
		sed -i 's/.PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
	else
		die "Usage: `basename $0` harden-ssh [option #]"
	fi
	service ssh restart
	printInfo "SSH hardening sucessful"
}

# info
function osInfo
{
	# Thanks for Mikel (http://unix.stackexchange.com/users/3169/mikel) for the code sample which was later modified a bit
	# http://unix.stackexchange.com/questions/6345/how-can-i-get-distribution-name-and-version-number-in-a-simple-shell-script
	ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

	. /etc/lsb-release
	OS=$DISTRIB_ID
	VERSION=$DISTRIB_RELEASE

	OS_SUMMARY=$OS
	OS_SUMMARY+=" "
	OS_SUMMARY+=$VERSION
	OS_SUMMARY+=" "
	OS_SUMMARY+=$ARCH
	OS_SUMMARY+="bit"

	printInfo "$OS_SUMMARY"
}

# fail2ban
function fail2banInstall {
	installer fail2ban fail2ban
	cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
	service fail2ban restart
	printWarn "Fail2ban's config file is located in /etc/fail2ban/jail.local"

}

############################################################
# Nginx/Web Server commands
############################################################

function addSite
{
	if [ -z "$1" ]
	then
		die "Usage: `basename $0` add-site [website name]"
	fi
	cd /sites
	mkdir -p $1/public
	wwwPermissions
	cp /etc/nginx/sites-available/example.com /etc/nginx/sites-available/$1.conf # use example site
	sed -i "s/example.com/$1/g" "/etc/nginx/sites-available/$1.conf" # change example.com to domain name
	cd ~
	printInfo "$1 was added successfully"
}

function removeSite
{
	if [ -z "$1" ]
	then
		die "Usage: `basename $0` remove-site [website name]"
	fi
	cd /sites
	rm -rf $1
	cd ~
	rm /etc/nginx/sites-available/$1.conf
	rm /etc/nginx/sites-enabled/$1.conf
	service nginx restart
	printInfo "$1 was removed successfully"
}

function enableSite
{
	if [ -z "$1" ]
	then
		die "Usage: `basename $0` enable-site [website name]"
	fi
	if [ -L /etc/nginx/sites-enabled/$1.conf ]
	then
		printWarn "$1 already enabled"
	elif [ ! -f /etc/nginx/sites-available/$1.conf ]
	then
		printWarn "A config for $1 does not exsist. Please use the add-site command"
	else
		ln -s /etc/nginx/sites-available/$1.conf /etc/nginx/sites-enabled/$1.conf
		service nginx restart
		printInfo "$1 was enabled successfully"
	fi
}

function disableSite
{
	if [ -z "$1" ]
	then
		die "Usage: `basename $0` disable-site [website name]"
	fi
	if [ ! -f /etc/nginx/sites-available/$1.conf ]
	then
		printWarn "A config for $1 does not exsist. Please use the add-site command"
	elif [ ! -L /etc/nginx/sites-enabled/$1.conf ]
	then
		printWarn "$1 is not enabled"
	else
		rm /etc/nginx/sites-enabled/$1.conf
		service nginx restart
		printInfo "$1 was disabled successfully"
	fi
}

function editSite
{
	if [ -z "$1" ]
	then
		die "Usage: `basename $0` edit-site [website name]"
	elif [ ! -f /etc/nginx/sites-available/$1.conf ]
	then
		die "A config for $1 does not exsist. Please use the add-site command"
	else
		nano /etc/nginx/sites-available/$1.conf
	fi
}

function editNginxConfig
{
	cd /etc/nginx
	nano /etc/nginx/nginx.conf
}

# www-restart
function wwwRestart
{
	service php5-fpm restart
	service nginx restart
}

# permissions
function wwwPermissions
{
	if [ -z "$1" ]
	then
		chown -R deploy:deploy /sites
		printInfo "User deploy is now the owner of the www directory"
	else
		chown -R $1:$1 /sites
		printInfo "User $1 is now the owner of the www directory"
	fi
}

########################################################################
# Start of script
########################################################################

checkSanity
case "$1" in
# main options
setup)
	baseSetup
	;;
ufw)
	installUfw $2
	;;
www)
	installWWW
	;;
mariadb)
	installMariadb
	;;
# other options/custom commands
update-wwwu)
	updateWwwUbuntu
	;;
harden-ssh)
	hardenSsh $2
	;;
permissions)
	wwwPermissions $2
	;;
restart)
	wwwRestart
	;;
fail2ban)
	fail2banInstall
	;;
info)
	osInfo
	;;
ip)
	getIp
	;;
updater)
	runUpdater
	;;
locale)
	fixLocale
	;;
test)
	runTests
	;;
add-site)
	addSite $2
	;;
remove-site)
	removeSite $2
	;;
enable-site)
	enableSite $2
	;;
disable-site)
	disableSite $2
	;;
edit-site)
	editSite $2
	;;
nginx-config)
	editNginxConfig
	;;
*)
	osInfo
	echo '  '
	echo 'Usage:' `basename $0` '[option] [argument]'
	echo '  '
	echo 'Main options (in recomended order):'
	echo '  - setup                   (Remove unneeded, upgrade system, install software)'
	echo '  - ufw [ssh port]          (Setup basic firewall with HTTP(S) and SSH open)'
	echo '  - www                     (Install Ngnix, PHP, and Pagespeed)'
	echo '  - mariadb                 (Install MySQL alternative and set root password)'
	echo '  '
	echo 'Extra options and custom commands:'
	echo '  - harden-ssh [option #]   (Hardens openSSH with PermitRoot and PasswordAuthentication)'
	echo '  - fail2ban                (Installs fail2ban and creates a config file)'
	echo '  - info                    (Displays information about the OS, ARCH and VERSION)'
	echo '  - ip                      (Displays the external IP address of the server)'
	echo '  - updater                 (Updates/upgrades packages, no release upgrades)'
	echo '  - update-wwwu             (Updates www-ubuntu and keeps current config file)'
	echo '  - locale                  (Fix locales issue with OpenVZ Ubuntu templates)'
	echo '  - test                    (Run the classic disk IO and classic cachefly network test)'
	echo '  '
	echo 'Nginx website commands:'
	echo '  - restart                 (Restarts Ngnix and PHP-FPM)'
	echo '  - permissions             (Make sure the proper permissions are set for /var/www/)'
	echo '  - add-site [website]      (Creates folder structure and empty config)'
	echo '  - remove-site [website]   (Deletes folder structure and config)'
	echo '  - enable-site [website]   (Creates symlink to sites-enabled)'
	echo '  - disable-site [website]  (Deletes symlink to sites-enabled)'
	echo '  - edit-site [website]     (Opens website config in nano)'
	echo '  - nginx-config            (Opens Nginx config in nano)'
	echo '  '
	;;
esac
