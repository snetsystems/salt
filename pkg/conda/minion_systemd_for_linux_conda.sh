#!/bin/sh

conda_install() {
    ### create logrotate.d
    echo "$PREFIX/var/log/salt/minion {
        weekly
        missingok
        rotate 7
        compress
        notifempty
    }" > /etc/logrotate.d/snet-salt

    ### create salt-minion service
    echo "[Unit]
Description=The Salt Minion
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
    systemctl enable snet-salt-minion.service > /dev/null 2>&1
    echo "Create Success snet-salt-minion.service"
    echo "Install Complete!"
    printf "Do you want to start the 'snet-salt-minion.service' [y/n]?"
    read -r SERVICE
    if [ "$SERVICE" == "y" ]; then
        systemctl start snet-salt-minion
    fi

    return 0
}

PREFIX=/opt/miniconda3/envs/saltenv
USAGE="
usage: $0 [options]

Installs Miniconda3 & Salt-Minion

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