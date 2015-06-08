#!/bin/bash
# Project URL: https://github.com/marshallford/basebuntu
# Author: Marshall Ford

ubuntuVersionRequired="14.04"

NGINX="1.8.0"
PAGESPEED="1.9.32.3"
WWWUSER="deploy"
RUBY="2.2.1"

############################################################
# Base Functions
############################################################

# installer [nick-name] [what to install]
# example: installer best-text-editor nano
# example: installer text-editors nano vim vi emacs
function installer
{
    nickName=$1
    toInstall=$2
    DEBIAN_FRONTEND=noninteractive apt-get -q -y install "$toInstall"
    runCleaner
    printInfo "$nickName installed"
}

# uninstaller [nick-name] [what to uninstall]
# example: uninstaller apache2 'apache2*'
# example: uninstaller web-server 'nginx*'
function uninstaller
{
    nickName=$1
    toUninstall=$2
    DEBIAN_FRONTEND=noninteractive apt-get -q -y remove --purge "$toUninstall"
    runCleaner
    printInfo "$nickName uninstalled"

}

# apt-get cleaner
function runCleaner
{
    apt-get -q -y autoremove
    apt-get -q -y autoclean
    apt-get -q -y clean
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
    if [ "$version" != "$ubuntuVersionRequired" ]
    then
        die "Distribution is not supported"
    fi
}

# always start at location of script
function scriptLocation
{
    DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
    if [ "$1" == "echo" ]
    then
        echo $DIR
    else
        cd $DIR
    fi
}

checkSanity
SCRIPTLOCATION=`scriptLocation "echo"`
scriptLocation

########################################################################
# Load in modules
########################################################################

for modules in modules/*.sh
do
    source $modules
done

########################################################################
# Start of script
########################################################################

case "$1" in
# main options
setup)
    initialSetup
    ;;
ufw)
    installUfw $2
    ;;
nginx)
    installNginx
    ;;
mariadb)
    installMariadb
    ;;
ruby)
    installRuby
    ;;
# other options/custom commands
update-bb)
    updateBasebuntu
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
    echo 'Usage:' $(basename $0) '[option] [argument]'
    echo '  '
    echo 'Main options (in recomended order):'
    echo '  - setup                   (Remove unneeded, upgrade system, install software)'
    echo '  - ufw [ssh port]          (Setup basic firewall with HTTP(S) and SSH open)'
    echo '  - nginx                   (Install Ngnix, PHP-FPM, and Pagespeed)'
    echo '  - mariadb                 (Install MySQL alternative and set root password)'
    echo '  - ruby                    (Install Ruby with RVM)'
    echo '  '
    echo 'Extra options and custom commands:'
    echo '  - harden-ssh [option #]   (Hardens openSSH with PermitRoot and PasswordAuthentication)'
    echo '  - fail2ban                (Installs fail2ban and creates a config file)'
    echo '  - info                    (Displays information about the OS, ARCH and VERSION)'
    echo '  - ip                      (Displays the external IP address of the server)'
    echo '  - updater                 (Updates/upgrades packages, no release upgrades)'
    echo '  - update-bb               (Updates basebuntu and keeps current config file)'
    echo '  - locale                  (Fix locales issue with OpenVZ Ubuntu templates)'
    echo '  - test                    (Run the classic disk IO and classic cachefly network test)'
    echo '  '
    echo 'Nginx website commands:'
    echo '  - restart                 (Restarts Ngnix and PHP-FPM)'
    echo '  - permissions             (Make sure the proper permissions are set for /var/www/)'
    echo '  - nginx-config            (Opens Nginx config in nano)'
    echo '  - add-site [website]      (Creates folder structure and empty config)'
    echo '  - remove-site [website]   (Deletes folder structure and config)'
    echo '  - enable-site [website]   (Creates symlink to sites-enabled)'
    echo '  - disable-site [website]  (Deletes symlink to sites-enabled)'
    echo '  - edit-site [website]     (Opens website config in nano)'
    echo '  '
    ;;
esac
