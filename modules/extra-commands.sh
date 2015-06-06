# Extra commands

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

# basebuntu updater
function updateBasebuntu
{
    $SCRIPTLOCATION = scriptLocation
    cp $SCRIPTLOCATION/conf/basebuntu.conf ~/basebuntu.conf.tmp
    scriptLocation "cd"
    git reset --hard HEAD
    git pull
    chmod +x basebuntu.sh
    rm $SCRIPTLOCATION/conf/basebuntu.conf
    mv ~/basebuntu.conf.tmp $SCRIPTLOCATION/conf/basebuntu.conf
    printInfo "Updated basebuntu successfully"
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
        die "Usage: $(basename $0) harden-ssh [option #]"
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
        die "Usage: $(basename $0) harden-ssh [option #]"
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

    echo $OS_SUMMARY
}

# fail2ban
function fail2banInstall {
    installer fail2ban fail2ban
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    service fail2ban restart
    printWarn "Fail2ban's config file is located in /etc/fail2ban/jail.local"

}
