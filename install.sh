#!/bin/bash
set -euo pipefail

sudo yum install -y -q --nogpgcheck tar util-linux wget zip unzip gcc which vim curl nano zsh jq
sudo yum install -y -q "${JAVA_INSTALLER}" glibc* glibc.i686 libgcc rng-tools

PORTS=($(echo "${JSON_PORTS}" | jq -r '.[]'))

sudo tee -a /etc/sysctl.d/99-sysctl.conf <<EOF
vm.swappiness=1
EOF

sudo tee -a /etc/security/limits.d/20-nproc.conf <<EOF
*          soft    nproc     10240
EOF

sudo tee -a /etc/security/limits.d/amb-sockets.conf <<EOF
*          soft    nofile     16000
*          hard    nofile     16000
EOF

sudo tee /etc/selinux/config <<EOF
SELINUX=permissive
SELINUXTYPE=targeted
EOF

sudo mkdir -p /opt/servicenow
sudo chmod 750 /opt/servicenow

aws s3 cp "s3://${BUCKET}/${KEY}" /tmp/sn.zip

sudo useradd servicenow || true
SERVICE=""

for PORT in "${PORTS[@]}"; do

    sudo java -jar /tmp/*.zip --dst-dir "/glide/nodes/sn_${PORT}" install -n sn -p "${PORT}"
    sudo chown -R servicenow:servicenow "/glide/nodes/sn_${PORT}"

    if [ "${PORT}" -eq 8443 ]; then
        SERVICE="snc_8443.service"
        echo "Building ServiceNow UI NODE Service ${SERVICE} @ ${PORT}"
    elif [ "${PORT}" -eq 9443 ]; then
        SERVICE="snc_9443.service"
        echo "Building ServiceNow WORKER NODE Service ${SERVICE} @ ${PORT}"
    fi

    echo "Completed glide script"
    sudo touch "/etc/systemd/system/${SERVICE}"

    sudo tee "/etc/systemd/system/${SERVICE}" <<EOF
[Unit]
Description=ServiceNow Tomcat Container
After=syslog.target

[Service]
Type=forking
Environment="JAVA_HOME=/usr"
ExecStart=/glide/nodes/sn_${PORT}/startup.sh
ExecStop=/glide/nodes/sn_${PORT}/shutdown.sh
User=servicenow
Group=servicenow
UMask=0007
LimitNOFILE=16000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable "${SERVICE}"
done

sudo yum clean all
rm -f /tmp/*.zip
