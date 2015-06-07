# Nginx/PHP-FPM

function installNginx
{
    scriptLocation
    source conf/basebuntu.conf
    if [ "$hasInstallNginxRun" = true ]
    then
        die "installNginx has already been run, if run again conflicts will be created"
    fi
    # Create user
    adduser $WWWUSER

    # PHP-FPM
    # https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mysql-php-lemp-stack-on-ubuntu-14-04
    installer php5 php5-fpm php5-mysql php-apc
    sed -i "s/user = www-data/user = $WWWUSER/" /etc/php5/fpm/pool.d/www.conf
    sed -i "s/group = www-data/group = $WWWUSER/" /etc/php5/fpm/pool.d/www.conf
    sed -i "s/listen.owner = www-data/listen.owner = $WWWUSER/" /etc/php5/fpm/pool.d/www.conf
    sed -i "s/listen.group = www-data/listen.group = $WWWUSER/" /etc/php5/fpm/pool.d/www.conf
    chown $WWWUSER:$WWWUSER /var/run/php5-fpm.sock
    service php5-fpm restart

    # Nginx & Pagespeed from source
    scriptLocation
    mkdir -p temp
    cd temp
    installer nginx-dependencies build-essential zlib1g-dev libpcre3 libpcre3-dev
    wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${PAGESPEED}-beta.zip
    unzip release-${PAGESPEED}-beta.zip
    cd ngx_pagespeed-release-${PAGESPEED}-beta/
    wget https://dl.google.com/dl/page-speed/psol/${PAGESPEED}.tar.gz
    tar -xzvf ${PAGESPEED}.tar.gz  # extracts to psol/
    scriptLocation
    cd temp
    wget http://nginx.org/download/nginx-$NGINX.tar.gz # download nginx
    tar -xvzf nginx-$NGINX.tar.gz # uncompress nginx
    cd nginx-$NGINX/
    ./configure --sbin-path=/usr/local/sbin --conf-path=/etc/nginx/nginx.conf --user=$WWWUSER --group=$WWWUSER --lock-path=/var/lock/nginx.lock --pid-path=/var/run/nginx.pid --add-module=$SCRIPTLOCATION/temp/ngx_pagespeed-release-$PAGESPEED-beta --with-http_spdy_module --with-http_ssl_module --with-http_realip_module
    make
    make install
    # H5BP
    scriptLocation
    cd temp
    mkdir -p h5bp
    cd h5bp
    H5BP=`pwd`
    git clone https://github.com/h5bp/server-configs-nginx.git .
    cp -r $H5BP /etc/nginx/
    # Load in custom nginx.conf
    rm /etc/nginx/nginx.conf
    cp $SCRIPTLOCATION/conf/nginx/nginx.conf /etc/nginx/nginx.conf
    # Load in nginx init script
    cp $SCRIPTLOCATION/conf/nginx/nginx-init /etc/init.d/nginx
    chmod +x /etc/init.d/nginx
    /usr/sbin/update-rc.d -f nginx defaults
    # Load in custom confs
    cp $SCRIPTLOCATION/conf/nginx/pagespeed.conf /etc/nginx/pagespeed.conf
    cp $SCRIPTLOCATION/conf/nginx/php-fpm.conf /etc/nginx/enable-php.conf
    # Load in h5bp/server-configs-nginx mime.types
    rm /etc/nginx/mime.types
    cp $H5BP/mime.types /etc/nginx/mime.types
    # Load in h5bp/server-configs-nginx examples
    cp -R $H5BP/sites-available/ /etc/nginx/H5BP-site-templates/
    # no-default site
    cp -R /etc/nginx/H5BP-site-templates/no-default /etc/nginx/sites-available/
    ln -s /etc/nginx/sites-available/no-default /etc/nginx/sites-enabled/no-default
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
    wwwPermissions

    # clean up
    rm -rf $SCRIPTLOCATION/temp
    # finishing touches
    rm -rf /usr/share/nginx/html # remove default website
    wwwRestart
    scriptLocation
    sed -i 's/hasInstallWWWRun.*/hasInstallWWWRun=true/' conf/basebuntu.conf
}
