# Initial setup

# Standard list of tools commonly used
function baseInstaller
{
    installer text-editors nano vim # text editors
    installer iftop iftop # show network usage
    installer nload nload # visualize network usage
    installer htop htop # task manager
    installer mc mc # file explorer
    installer archive-tools unzip zip
    installer curl curl # alternative to wget
    installer screen screen
    installer gt5 gt5 # visual disk usage
    installer nslookup dnsutils # dns tools
    ppaGit # version control
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
    installer ppa-support python-software-properties software-properties-common
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
    echo "alias basebuntu='/root/basebuntu/basebuntu.sh'" >> /root/.bashrc
    echo "alias bb='/root/basebuntu/basebuntu.sh'" >> /root/.bashrc
    source /root/.bashrc
}

function initialSetup
{
    scriptLocation
    cd conf
    source basebuntu.conf
    if [ "$hasInitalSetupRun" = false ]
    then
        setTimezone
        removeUneededPackages
        runUpdater
        hardenSysctl
        ppaSupport
        baseInstaller
        runCleaner
        scriptAliases
        sed -i 's/hasInitalSetupRun.*/hasInitalSetupRun=true/' basebuntu.conf
    else
        printWarn "Inital setup has already been run"
    fi
}
