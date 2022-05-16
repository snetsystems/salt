#!/bin/sh

conda_install() {
    ### create logrotate.d
    echo "$PREFIX/var/log/salt/master {
    weekly
    missingok
    rotate 5
    compress
    notifempty
}

$PREFIX/var/log/salt/minion {
    weekly
    missingok
    rotate 5
    compress
    notifempty
}

$PREFIX/var/log/salt/key {
    weekly
    missingok
    rotate 5
    compress
    notifempty
}

$PREFIX/var/log/salt/cloud {
    weekly
    missingok
    rotate 5
    compress
    notifempty
}

$PREFIX/var/log/salt/ssh {
    weekly
    missingok
    rotate 5
    compress
    notifempty
}" > /etc/logrotate.d/snet-salt

    ### create salt  services
    echo "[Unit]
Description=The Salt Master Server of SnetSystems
After=network.target

[Service]
LimitNOFILE=100000
Type=notify
NotifyAccess=all
ExecStart=$PREFIX/bin/python $PREFIX/bin/salt-master -c '$PREFIX/etc/salt'

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/snet-salt-master.service
    echo "[Unit]
Description=The Salt API of SnetSystems
After=network.target

[Service]
Type=notify
NotifyAccess=all
LimitNOFILE=8192
ExecStart=$PREFIX/bin/python $PREFIX/bin/salt-api -c '$PREFIX/etc/salt'
TimeoutStopSec=3

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/snet-salt-api.service
    echo "[Unit]
Description=The Salt Minion of SnetSystems
After=network.target

[Service]
KillMode=process
Type=notify
NotifyAccess=all
LimitNOFILE=8192
ExecStart=$PREFIX/bin/python $PREFIX/bin/salt-minion -c '$PREFIX/etc/salt'

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/snet-salt-minion.service

    systemctl daemon-reload > /dev/null 2>&1
    systemctl enable snet-salt-master snet-salt-api snet-salt-minion > /dev/null 2>&1
    echo "snet-salt-master snet-salt-api snet-salt-minion services are created and enabled"
    printf "Do you want to start the 'snet-salt' services? [y/n]"
    read -r IS_START
    if [ "$IS_START" == "y" ]; then
        systemctl start snet-salt-master snet-salt-api snet-salt-minion
        systemctl status snet-salt-master snet-salt-api snet-salt-minion
    fi

    return 0
}

PREFIX=/opt/miniconda3/envs/saltenv
USAGE="
usage: $0 [options]

Install SNET salt services

-p          Set installed miniconda prefix path (default: /opt/miniconda3/envs/saltenv)"

while getopts "p:h" x; do
    case "$x" in
        h)
            printf "%s\\n" "$USAGE"
            exit 2
            ;;
        p)
            PREFIX="$OPTARG"
            ;;
        ?)
            printf "ERROR: did not recognize option '%s', please try -h\\n" "$x"
            exit 1
            ;;
    esac
done

conda_install
