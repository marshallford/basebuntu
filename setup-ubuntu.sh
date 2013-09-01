#!/bin/bash

############################################################
# core functions
############################################################

function check_install {
	if [ -z "`which "$1" 2>/dev/null`" ]
	then
		executable=$1
		shift
		while [ -n "$1" ]
		do
			DEBIAN_FRONTEND=noninteractive apt-get -q -y install "$1"
			apt-get clean
			print_info "$1 installed for $executable"
			shift
		done
	else
		print_warn "$2 already installed"
	fi
}

function check_remove {
	if [ -n "`which "$1" 2>/dev/null`" ]
	then
		DEBIAN_FRONTEND=noninteractive apt-get -q -y remove --purge "$2"
		apt-get clean
		print_info "$2 removed"
	else
		print_warn "$2 is not installed"
	fi
}

function check_sanity {
	# Do some sanity checking.
	if [ $(/usr/bin/id -u) != "0" ]
	then
		die 'Must be run by root user'
	fi

	if [ ! -f /etc/debian_version ]
	then
		die "Distribution is not supported"
	fi
}

function die {
	echo "ERROR: $1" > /dev/null 1>&2
	exit 1
}

function get_domain_name() {
	# Getting rid of the lowest part.
	domain=${1%.*}
	lowest=`expr "$domain" : '.*\.\([a-z][a-z]*\)'`
	case "$lowest" in
	com|net|org|gov|edu|co|me|info|name)
		domain=${domain%.*}
		;;
	esac
	lowest=`expr "$domain" : '.*\.\([a-z][a-z]*\)'`
	[ -z "$lowest" ] && echo "$domain" || echo "$lowest"
}

function get_password() {
	# Check whether our local salt is present.
	SALT=/var/lib/radom_salt
	if [ ! -f "$SALT" ]
	then
		head -c 512 /dev/urandom > "$SALT"
		chmod 400 "$SALT"
	fi
	password=`(cat "$SALT"; echo $1) | md5sum | base64`
	echo ${password:0:13}
}

function print_info {
	echo -n -e '\e[1;36m'
	echo -n $1
	echo -e '\e[0m'
}

function print_warn {
	echo -n -e '\e[1;33m'
	echo -n $1
	echo -e '\e[0m'
}


############################################################
# applications
############################################################

function install_dash {
	check_install dash dash
	rm -f /bin/sh
	ln -s dash /bin/sh
}

function install_nano {
	check_install nano nano
}

function install_htop {
	check_install htop htop
}

function install_mc {
	check_install mc mc
}

function install_iotop {
	check_install iotop iotop
}

function install_iftop {
	check_install iftop iftop
	print_warn "Run IFCONFIG to find your net. device name"
	print_warn "Example usage: iftop -i venet0"
}

function install_vim {
	check_install vim vim
}

function install_git {
	check_install git git
}

function install_syslogd {
	# We just need a simple vanilla syslogd. Also there is no need to log to
	# so many files (waste of fd). Just dump them into
	# /var/log/(cron/mail/messages)
	check_install /usr/sbin/syslogd inetutils-syslogd
	invoke-rc.d inetutils-syslogd stop

	for file in /var/log/*.log /var/log/mail.* /var/log/debug /var/log/syslog
	do
		[ -f "$file" ] && rm -f "$file"
	done
	for dir in fsck news
	do
		[ -d "/var/log/$dir" ] && rm -rf "/var/log/$dir"
	done

	cat > /etc/syslog.conf <<END
*.*;mail.none;cron.none -/var/log/messages
cron.*				  -/var/log/cron
mail.*				  -/var/log/mail
END

	[ -d /etc/logrotate.d ] || mkdir -p /etc/logrotate.d
	cat > /etc/logrotate.d/inetutils-syslogd <<END
/var/log/cron
/var/log/mail
/var/log/messages {
	rotate 4
	weekly
	missingok
	notifempty
	compress
	sharedscripts
	postrotate
		/etc/init.d/inetutils-syslogd reload >/dev/null
	endscript
}
END

	invoke-rc.d inetutils-syslogd start
}

function install_ufw {

	check_install ufw ufw

	if [ -z "$1" ]
	then
		die "Usage: `basename $0` ufw [ssh-port-#]"
	fi

	# Reconfigure sshd - change port
    sed -i 's/^Port [0-9]*/Port '$1'/' /etc/ssh/sshd_config
    service ssh reload

	ufw disable
	ufw default allow outgoing
	ufw default deny incoming
	ufw allow http
	ufw allow https
	ufw allow $1
	ufw enable

}

function install_mariadb {

	# Install dependencies and repository
	check_install python-software-properties python-software-properties
	apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
	add-apt-repository 'deb http://ftp.osuosl.org/pub/mariadb/repo/10.0/ubuntu precise main'
	apt-get update

	# Install the MariaDB packages
	check_install mariadb-server mariadb-server

	invoke-rc.d mysql start
	read -p "MariaDB root password: " passwd
	mysqladmin password "$passwd"

	print_warn "Respond YES to all questions asked to secure your MariaDB install"
	mysql_secure_installation
}

function install_php {
	# PHP core
	check_install php5-fpm php5-fpm
	check_install php5-cli php5-cli

	# PHP modules
	DEBIAN_FRONTEND=noninteractive apt-get -y install php5-apc php5-suhosin php5-curl php5-gd php5-intl php5-mcrypt php-gettext php5-mariadb php5-sqlite

	echo 'Using PHP-FPM to manage PHP processes'
	echo ' '

        print_info "Taking configuration backups in /root/bkps; you may keep or delete this directory"
        mkdir /root/bkps
	mv /etc/php5/conf.d/apc.ini /root/bkps/apc.ini

cat > /etc/php5/conf.d/apc.ini <<END
[APC]
extension=apc.so
apc.enabled=1
apc.shm_segments=1
apc.shm_size=48M
apc.ttl=7200
apc.user_ttl=7200
apc.num_files_hint=1024
apc.mmap_file_mask=/tmp/apc.XXXXXX
apc.max_file_size = 1M
apc.post_max_size = 1000M
apc.upload_max_filesize = 1000M
apc.enable_cli=0
apc.rfc1867=0
END

	mv /etc/php5/conf.d/suhosin.ini /root/bkps/suhosin.ini

cat > /etc/php5/conf.d/suhosin.ini <<END
; configuration for php suhosin module
extension=suhosin.so
suhosin.executor.include.whitelist="phar"
suhosin.request.max_vars = 2048
suhosin.post.max_vars = 2048
suhosin.request.max_array_index_length = 256
suhosin.post.max_array_index_length = 256
suhosin.request.max_totalname_length = 8192
suhosin.post.max_totalname_length = 8192
suhosin.sql.bailout_on_error = Off
END

	cp /etc/php5/fpm/pool.d/www.conf /root/bkps/www.conf
	cat /root/bkps/www.conf | sed 's#127.0.0.1:9000#"unix:/var/run/php5-fpm.sock/"#' > /etc/php5/fpm/pool.d/www.conf


	if [ -f /etc/php5/fpm/php.ini ]
		then
			sed -i \
				"s/upload_max_filesize = 2M/upload_max_filesize = 200M/" \
				/etc/php5/fpm/php.ini
			sed -i \
				"s/post_max_size = 8M/post_max_size = 200M/" \
				/etc/php5/fpm/php.ini
			sed -i \
				"s/memory_limit = 128M/memory_limit = 156M/" \
				/etc/php5/fpm/php.ini
	fi

	invoke-rc.d php5-fpm restart

}

function install_nginx {

	check_install nginx nginx

	mkdir -p /var/www

	# PHP-safe default vhost
	cat > /etc/nginx/sites-available/default_php <<END
# Creates unlimited domains for PHP sites as long as you add the
# entry to /etc/hosts and create the matching \$host folder.
server {
	listen 80 default;
	server_name _;
	root /var/www/\$host/public;
	index index.html index.htm index.php;

	# Directives to send expires headers and turn off 404 error logging.
	location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
		expires max;
		log_not_found off;
		access_log off;
	}

	location = /favicon.ico {
		log_not_found off;
		access_log off;
	}

	location = /robots.txt {
		allow all;
		log_not_found off;
		access_log off;
	}

	## Disable viewing .htaccess & .htpassword
	location ~ /\.ht {
		deny  all;
	}

	include /etc/nginx/php.conf;
}
END

	# MVC frameworks with only a single index.php entry point (nginx > 0.7.27)
	cat > /etc/nginx/php.conf <<END
# Route all requests for non-existent files to index.php
location / {
	try_files \$uri \$uri/ /index.php\$is_args\$args;
}

# Pass PHP scripts to php-fastcgi listening on port 9000
location ~ \.php$ {

	# Zero-day exploit defense.
	# http://forum.nginx.org/read.php?2,88845,page=3
	# Won't work properly (404 error) if the file is not stored on
	# this server,  which is entirely possible with php-fpm/php-fcgi.
	# Comment the 'try_files' line out if you set up php-fpm/php-fcgi
	# on another machine.  And then cross your fingers that you won't get hacked.
	try_files \$uri =404;

	include fastcgi_params;

	# Keep these parameters for compatibility with old PHP scripts using them.
	fastcgi_param PATH_INFO \$fastcgi_path_info;
	fastcgi_param PATH_TRANSLATED \$document_root\$fastcgi_path_info;
	fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;

	# Some default config
	fastcgi_connect_timeout        20;
	fastcgi_send_timeout          180;
	fastcgi_read_timeout          180;
	fastcgi_buffer_size          128k;
	fastcgi_buffers            4 256k;
	fastcgi_busy_buffers_size    256k;
	fastcgi_temp_file_write_size 256k;
	fastcgi_intercept_errors    on;
	fastcgi_ignore_client_abort off;
	fastcgi_pass   unix:/var/run/php5-fpm.sock;

}
# PHP search for file Exploit:
# The PHP regex location block fires instead of the try_files block. Therefore we need
# to add "try_files \$uri =404;" to make sure that "/uploads/virusimage.jpg/hello.php"
# never executes the hidden php code inside virusimage.jpg because it can't find hello.php!
# The exploit also can be stopped by adding "cgi.fix_pathinfo = 0" in your php.ini file.
END

	# remove localhost-config
	rm -f /etc/nginx/sites-available/default

	echo 'Created /etc/nginx/php.conf for PHP sites'
	echo 'Created /etc/nginx/sites-available/default_php sample vhost'
	echo ' '

 if [ -f /etc/nginx/nginx.conf ]
	then
		# one worker for each CPU and max 1024 connections/worker
		cpu_count=`grep -c ^processor /proc/cpuinfo`
		sed -i \
			"s/worker_processes [0-9]*;/worker_processes $cpu_count;/" \
			/etc/nginx/nginx.conf
		sed -i \
			"s/worker_connections [0-9]*;/worker_connections 1024;/" \
			/etc/nginx/nginx.conf
		# Enable advanced compression
		sed -i \
			"s/# gzip_/gzip_/g" \
			/etc/nginx/nginx.conf
 fi

	# restart nginx
	invoke-rc.d nginx restart
}

function install_site {

	if [ -z "$1" ]
	then
		die "Usage: `basename $0` site [domain]"
	fi

	# Setup folder
	mkdir /var/www/$1
	mkdir /var/www/$1/public

	# Setup default index.html file
	cat > "/var/www/$1/public/index.html" <<END
Hello World
END
	# Setting up Nginx mapping
	cat > "/etc/nginx/sites-available/$1.conf" <<END
server {
	listen [::]:80;
	server_name www.$1 $1;
	root /var/www/$1/public;
	index index.html index.htm index.php;
	client_max_body_size 32m;

	access_log  /var/www/$1/access.log;
	error_log  /var/www/$1/error.log;

	# Directives to send expires headers and turn off 404 error logging.
	location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
		expires max;
		log_not_found off;
		access_log off;
	}

	location = /favicon.ico {
		log_not_found off;
		access_log off;
	}

	location = /robots.txt {
		allow all;
		log_not_found off;
		access_log off;
	}

	## Disable viewing .htaccess & .htpassword
	location ~ /\.ht {
		deny  all;
	}

	include /etc/nginx/php.conf;
}
END
	# Create the link so nginx can find it
	ln -s /etc/nginx/sites-available/$1.conf /etc/nginx/sites-enabled/$1.conf

	# PHP/Nginx needs permission to access this
	chown www-data:www-data -R "/var/www/$1"

	invoke-rc.d nginx restart

	print_warn "New site successfully installed."
}

function install_wordpress {

	if [ -z "$1" ]
	then
		die "Usage: `basename $0` wordpress [domain]"
	fi

	# Setup folder
	mkdir /var/www/$1
	mkdir /var/www/$1/public

	# Downloading the WordPress' latest and greatest distribution.
    mkdir /tmp/wordpress.$$
    wget -O - http://wordpress.org/latest.tar.gz | \
        tar zxf - -C /tmp/wordpress.$$
    cp -a /tmp/wordpress.$$/wordpress/. "/var/www/$1/public"
    rm -rf /tmp/wordpress.$$
    cp "/var/www/$1/public/wp-config-sample.php" "/var/www/$1/public/wp-config.php"
    print_info "To finish your WP install create a database and edit wp-config.php (remember to use a secret key)"
	# Setting up Nginx mapping
	cat > "/etc/nginx/sites-available/$1.conf" <<END
server {
	listen 80;
	server_name www.$1 $1;
	root /var/www/$1/public;
	index index.php;

	access_log  /var/www/$1/access.log;
	error_log  /var/www/$1/error.log;

	# unless the request is for a valid file, send to bootstrap
	if (!-e \$request_filename)
    {
	    rewrite ^(.+)$ /index.php?q=$1 last;
    }
 
    # catch all
    error_page 404 /index.php;

    # Directives to send expires headers and turn off 404 error logging.
    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires max;
        log_not_found off;
        access_log off;
    }

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    ## Disable viewing .htaccess & .htpassword
    location ~ /\.ht {
        deny  all;
    }

    location / {
                # This is cool because no php is touched for static content. 
                # include the "?\$args" part so non-default permalinks doesn't break when using query string
                try_files \$uri \$uri/ /index.php?\$args;
        }

    # use fastcgi for all php files
    location ~ \.php$
    {
        try_files \$uri =404;

        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME /var/www/$1/public\$fastcgi_script_name;
        include fastcgi_params;

        # Some default config
        fastcgi_connect_timeout        20;
        fastcgi_send_timeout          180;
        fastcgi_read_timeout          180;
        fastcgi_buffer_size          128k;
        fastcgi_buffers            4 256k;
        fastcgi_busy_buffers_size    256k;
        fastcgi_temp_file_write_size 256k;
        fastcgi_intercept_errors    on;
        fastcgi_ignore_client_abort off;

    }

}


END
	# Create the link so nginx can find it
	ln -s /etc/nginx/sites-available/$1.conf /etc/nginx/sites-enabled/$1.conf

	# PHP/Nginx needs permission to access this
	chown www-data:www-data -R "/var/www/$1"

	invoke-rc.d nginx restart

	print_warn "New wordpress site successfully installed."
}

function remove_unneeded {
	# Some Debian have portmap installed. We don't need that.
	check_remove /sbin/portmap portmap

	# Remove rsyslogd, which allocates ~30MB privvmpages on an OpenVZ system,
	# which might make some low-end VPS inoperatable. We will do this even
	# before running apt-get update.
	check_remove /usr/sbin/rsyslogd rsyslog

	# Other packages that are quite common in standard OpenVZ templates.
	check_remove /usr/sbin/apache2 'apache2*'
	check_remove /usr/sbin/named 'bind9*'
	check_remove /usr/sbin/smbd 'samba*'
	check_remove /usr/sbin/nscd nscd

	# Need to stop sendmail as removing the package does not seem to stop it.
	if [ -f /usr/lib/sm.bin/smtpd ]
	then
		invoke-rc.d sendmail stop
		check_remove /usr/lib/sm.bin/smtpd 'sendmail*'
	fi
}

############################################################
# Harden openSSH
############################################################
function harden_ssh {
	if [ -z "$1" ]
	then
		die "Usage: `basename $0` harden_ssh [option #]"
	fi
	if [ "$1" == 1 ]
	then
		sed -i 's/PermitRootLogin yes/PermitRootLogin without-password/' /etc/ssh/sshd_config
		sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
	elif [ "$1" == 2 ]
	then
		sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
		sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
	elif [ "$1" == 3 ]
	then
		sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
	elif [ "$1" == 4 ]
	then
		sed -i 's/PermitRootLogin yes/PermitRootLogin without-password/' /etc/ssh/sshd_config
	else 
		die "Usage: `basename $0` harden_ssh [option #]"	
	fi
	print_info "SSH hardening sucessful"
}

############################################################
# Fail2ban install and config file move
############################################################
function f2b {
	check_install fail2ban fail2ban
	cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
	service fail2ban restart
	print_warn "Fail2ban's config file is located in /etc/fail2ban/jail.local"

}

############################################################
# Download ps_mem.py
############################################################
function install_ps_mem {
	wget http://www.pixelbeat.org/scripts/ps_mem.py -O ~/ps_mem.py
	chmod 700 ~/ps_mem.py
	print_info "ps_mem.py has been setup successfully"
	print_warn "Use ~/ps_mem.py to execute"
}

############################################################
# Update apt sources (Ubuntu only; not yet supported for debian)
############################################################
function update_apt_sources {
	eval `grep '^DISTRIB_CODENAME=' /etc/*-release 2>/dev/null`

	if [ "$DISTRIB_CODENAME" == "" ]
	then
		die "Unknown Ubuntu flavor $DISTRIB_CODENAME"
	fi

	cat > /etc/apt/sources.list <<END
## main & restricted repositories
deb http://us.archive.ubuntu.com/ubuntu/ $DISTRIB_CODENAME main restricted
deb-src http://us.archive.ubuntu.com/ubuntu/ $DISTRIB_CODENAME main restricted

deb http://security.ubuntu.com/ubuntu $DISTRIB_CODENAME-updates main restricted
deb-src http://security.ubuntu.com/ubuntu $DISTRIB_CODENAME-updates main restricted

deb http://security.ubuntu.com/ubuntu $DISTRIB_CODENAME-security main restricted
deb-src http://security.ubuntu.com/ubuntu $DISTRIB_CODENAME-security main restricted

## universe repositories - uncomment to enable
deb http://us.archive.ubuntu.com/ubuntu/ $DISTRIB_CODENAME universe
deb-src http://us.archive.ubuntu.com/ubuntu/ $DISTRIB_CODENAME universe

deb http://us.archive.ubuntu.com/ubuntu/ $DISTRIB_CODENAME-updates universe
deb-src http://us.archive.ubuntu.com/ubuntu/ $DISTRIB_CODENAME-updates universe

deb http://security.ubuntu.com/ubuntu $DISTRIB_CODENAME-security universe
deb-src http://security.ubuntu.com/ubuntu $DISTRIB_CODENAME-security universe
END

	print_info "/etc/apt/sources.list updated for "$DISTRIB_CODENAME
}

############################################################
# Install vzfree (OpenVZ containers only)
############################################################
function install_vzfree {
	print_warn "build-essential package is now being installed which will take additional diskspace"
	check_install build-essential build-essential
	cd ~
	wget http://hostingfu.com/files/vzfree/vzfree-0.1.tgz -O vzfree-0.1.tgz
	tar -vxf vzfree-0.1.tgz
	cd vzfree-0.1
	make && make install
	cd ..
	vzfree
	print_info "vzfree has been installed"
	rm -fr vzfree-0.1 vzfree-0.1.tgz
}

############################################################
# Classic Disk I/O and Network speed tests
############################################################
function runtests {
	print_info "Classic I/O test"
	print_info "dd if=/dev/zero of=iotest bs=64k count=16k conv=fdatasync && rm -fr iotest"
	dd if=/dev/zero of=iotest bs=64k count=16k conv=fdatasync && rm -fr iotest

	print_info "Network test"
	print_info "wget cachefly.cachefly.net/100mb.test -O 100mb.test && rm -fr 100mb.test"
	wget cachefly.cachefly.net/100mb.test -O 100mb.test && rm -fr 100mb.test
}

############################################################
# Print OS summary (OS, ARCH, VERSION)
############################################################
function show_os_arch_version {
	# Thanks for Mikel (http://unix.stackexchange.com/users/3169/mikel) for the code sample which was later modified a bit
	# http://unix.stackexchange.com/questions/6345/how-can-i-get-distribution-name-and-version-number-in-a-simple-shell-script
	ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

	if [ -f /etc/lsb-release ]; then
		. /etc/lsb-release
		OS=$DISTRIB_ID
		VERSION=$DISTRIB_RELEASE
	elif [ -f /etc/debian_version ]; then
		# Work on Debian and Ubuntu alike
		OS=$(lsb_release -si)
		VERSION=$(lsb_release -sr)
	elif [ -f /etc/redhat-release ]; then
		# Add code for Red Hat and CentOS here
		OS=Redhat
		VERSION=$(uname -r)
	else
		# Pretty old OS? fallback to compatibility mode
		OS=$(uname -s)
		VERSION=$(uname -r)
	fi

	OS_SUMMARY=$OS
	OS_SUMMARY+=" "
	OS_SUMMARY+=$VERSION
	OS_SUMMARY+=" "
	OS_SUMMARY+=$ARCH
	OS_SUMMARY+="bit"

	print_info "$OS_SUMMARY"
}

############################################################
# Fix locale for OpenVZ Ubuntu templates
############################################################
function fix_locale {
	check_install multipath-tools multipath-tools
	export LANGUAGE=en_US.UTF-8
	export LANG=en_US.UTF-8
	export LC_ALL=en_US.UTF-8

	# Generate locale
	locale-gen en_US.UTF-8
	dpkg-reconfigure locales
}

function apt_clean {
	apt-get -q -y autoclean
	apt-get -q -y clean
}

function update_upgrade {
	# Run through the apt-get update/upgrade first.
	# This should be done before we try to install any package
	apt-get -q -y update
	apt-get -q -y upgrade

	# also remove the orphaned stuff
	apt-get -q -y autoremove
}

function update_timezone {
	dpkg-reconfigure tzdata
}

######################################################################## 
# START OF PROGRAM
########################################################################
export PATH=/bin:/usr/bin:/sbin:/usr/sbin

check_sanity
case "$1" in
mariadb)
	install_mariadb
	;;
nginx)
	install_nginx
	;;
php)
	install_php
	;;
site)
	install_site $2
	;;
wordpress)
	install_wordpress $2
	;;
ufw)
	install_ufw $2
	;;	
ps_mem)
	install_ps_mem
	;;
apt)
	update_apt_sources
	;;
vzfree)
	install_vzfree
	;;
locale)
	fix_locale
	;;
test)
	runtests
	;;
harden_ssh)
	harden_ssh $2
	;;
fail2ban)
	f2b
	;;
info)
	show_os_arch_version
	;;
system)
	update_timezone
	remove_unneeded
	update_upgrade
	install_dash
	install_git
	install_vim
	install_nano
	install_htop
	install_mc
	install_iotop
	install_iftop
	install_syslogd
	apt_clean
	;;
*)
	show_os_arch_version
	echo '  '
	echo 'Usage:' `basename $0` '[option] [argument]'
	echo 'Available options (in recomended order):'
	echo '  - system                 (remove unneeded, upgrade system, install software)'
	echo '  - ufw [port]             (setup basic firewall with HTTP(S) open)'
	echo '  - MariaDB                (install MySQL alternative and set root password)'
	echo '  - nginx                  (install nginx and create sample PHP vhosts)'
	echo '  - php                    (install PHP5-FPM with APC, cURL, suhosin, etc...)'
	echo '  - site [domain.tld] 	 (create nginx vhost and /var/www/$site/public)'
	echo '  - wordpress [domain.tld] (create nginx vhost and /var/www/$wordpress/public)'
	echo '  '
	echo '... and now some extras'
	echo '  - harden_ssh [option #]  (Hardens openSSH with PermitRoot and PasswordAuthentication)'
	echo '  - fail2ban               (Installs fail2ban and creates a config file)'
	echo '  - info                   (Displays information about the OS, ARCH and VERSION)'
	echo '  - apt                    (update sources.list for UBUNTU only)'
	echo '  - ps_mem                 (Download the handy python script to report memory usage)'
	echo '  - vzfree                 (Install vzfree for correct memory reporting on OpenVZ VPS)'
	echo '  - motd                   (Configures and enables the default MOTD)'
	echo '  - locale                 (Fix locales issue with OpenVZ Ubuntu templates)'
	echo '  - test                   (Run the classic disk IO and classic cachefly network test)'
	echo '  '
	;;
esac
