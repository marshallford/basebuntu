# Initial setup

# Standard list of tools commonly used
function baseInstaller
{
    installer text-editors "nano vim" # text editors
    installer iftop iftop # show network usage
    installer nload nload # visualize network usage
    installer htop htop # task manager
    installer mc mc # file explorer
    installer archive-tools "unzip zip"
    installer curl curl # alternative to wget
    installer screen screen
    installer gt5 gt5 # visual disk usage
    installer "dns tools" "dnsutils" # dns tools
    ppaGit # version control
}

function removeUneededPackages
{
    # Apache
    service apache2 stop
    uninstaller apache "apache2*"
}

function setTimezone
{
    dpkg-reconfigure tzdata
}

function ppaSupport
{
    installer ppa-support "python-software-properties software-properties-common"
}

function hardenSysctl
{
    scriptLocation
    cd conf
    cat sysctl-append.conf >> /etc/sysctl.conf
    sysctl -p > /dev/null
}

function ppaGit
{
    add-apt-repository ppa:git-core/ppa -y
    apt-get update
    apt-get upgrade -y # git was installed to pull in basebuntu
    printInfo "git was upgraded to the ppa verison"
}

function scriptAliases
{
    echo "alias basebuntu='/root/.basebuntu/basebuntu.sh'" >> /root/.bashrc
    echo "alias bb='/root/.basebuntu/basebuntu.sh'" >> /root/.bashrc
}

function initialSetup
{
    scriptLocation
    source conf/basebuntu.conf
    if [ "$hasInitialSetupRun" = false ]
    then
        setTimezone
        removeUneededPackages
        runUpdater
        hardenSysctl
        ppaSupport
        baseInstaller
        runCleaner
        scriptAliases
        scriptLocation
        sed -i 's/hasInitialSetupRun.*/hasInitialSetupRun=true/' conf/basebuntu.conf
    else
        printWarn "Initial setup has already been run"
    fi
}
