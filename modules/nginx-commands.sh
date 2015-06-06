# Nginx commands

function addSite
{
    if [ -z "$1" ]
    then
        die "Usage: $(basename $0) add-site [website name]"
    fi
    cd /sites
    mkdir -p $1/public
    wwwPermissions
    cp /etc/nginx/H5BP-site-templates/example.com /etc/nginx/sites-available/$1.conf # use example site
    sed -i "s/example.com/$1/g" "/etc/nginx/sites-available/$1.conf" # change example.com to domain name
    cd ~
    printInfo "$1 was added successfully"
}

function removeSite
{
    if [ -z "$1" ]
    then
        die "Usage: $(basename $0) remove-site [website name]"
    fi
    cd /sites
    rm -rf $1
    cd ~
    rm /etc/nginx/sites-available/$1.conf
    rm /etc/nginx/sites-enabled/$1.conf
    wwwRestart
    printInfo "$1 was removed successfully"
}

function enableSite
{
    if [ -z "$1" ]
    then
        die "Usage: $(basename $0) enable-site [website name]"
    fi
    if [ -L /etc/nginx/sites-enabled/$1.conf ]
    then
        printWarn "$1 already enabled"
    elif [ ! -f /etc/nginx/sites-available/$1.conf ]
    then
        printWarn "A config for $1 does not exsist. Please use the add-site command"
    else
        ln -s /etc/nginx/sites-available/$1.conf /etc/nginx/sites-enabled/$1.conf
        wwwRestart
        printInfo "$1 was enabled successfully"
    fi
}

function disableSite
{
    if [ -z "$1" ]
    then
        die "Usage: $(basename $0) disable-site [website name]"
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
    wwwRestart
}

function editSite
{
    if [ -z "$1" ]
    then
        die "Usage: $(basename $0) edit-site [website name]"
    elif [ ! -f /etc/nginx/sites-available/$1.conf ]
    then
        die "A config for $1 does not exsist. Please use the add-site command"
    else
        nano /etc/nginx/sites-available/$1.conf
    fi
    wwwRestart
}

function editNginxConfig
{
    nano /etc/nginx/nginx.conf
    if ask "Do you want restart nginx and php-fpm?"; then
        wwwRestart
    fi
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
