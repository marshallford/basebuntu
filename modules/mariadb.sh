# MariaDB

function installMariadb
{
    apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
    add-apt-repository 'deb http://mirror.stshosting.co.uk/mariadb/repo/10.0/ubuntu trusty main'
    apt-get update
    installer mariadb mariadb-server
    service mysql start
    printInfo "Respond YES to all questions asked to secure your MariaDB install"
    mysql_secure_installation
}
