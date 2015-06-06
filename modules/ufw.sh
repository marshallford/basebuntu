# UFW

function installUfw
{
    if [ -z "$1" ]
    then
        die "Usage: $(basename $0) firewall [ssh port]"
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
    ufw status
}
