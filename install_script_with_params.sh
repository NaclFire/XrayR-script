#!/bin/bash

# Disable dmesg
systemctl disable dmesg

# Stop and disable rsyslog
service rsyslog stop
systemctl disable rsyslog

# Update package information
apt-get --allow-releaseinfo-change update

# Install required packages
apt-get install vim curl wget git sudo net-tools zip unzip -y

# Install XrayR
wget -N https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh && bash install.sh

# Read user input for XrayR configuration
read -p "Enter XrayR listening address (e.g., http://127.0.0.1:667): " xray_addr
read -p "Enter XrayR mu_key: " xray_uuid
read -p "Enter XrayR alterId : " xray_alterid

# Update XrayR configuration file
sed -i "s#^\\s*\"address\":.*#  \"address\": \"${xray_addr}\",#" /etc/XrayR/config.yml
sed -i "s#^\\s*\"id\":.*#  \"id\": \"${xray_uuid}\",#" /etc/XrayR/config.yml
sed -i "s#^\\s*\"alterId\":.*#  \"alterId\": ${xray_alterid},#" /etc/XrayR/config.yml

# Change CertMode to none in the XrayR configuration file
sed -i "s#^\\s*\"CertMode\":.*#  \"CertMode\": \"none\",#" /etc/XrayR/config.yml

# Install gost
mkdir gost && cd gost
wget -N --no-check-certificate https://github.com/ginuerzh/gost/releases/download/v2.11.1/gost-linux-amd64-2.11.1.gz
gzip -d gost-linux-amd64-2.11.1.gz
mv gost-linux-amd64-2.11.1 gost
chmod +x gost

# Create gost service file
cat <<EOF > /etc/systemd/system/gost.service
[Unit]
Description=gost
After=network.target
Wants=network.target

[Service]
Type=simple
WorkingDirectory=/root/gost
ExecStart=/root/gost/gost -C /root/gost/gost.json
Restart=always
RestartSec=10s
ExecStop=/usr/bin/kill gost
LimitNOFILE=655350
LimitCORE=infinity
LimitNPROC=655350

[Install]
WantedBy=multi-user.target
EOF

# Enable and start gost service
systemctl enable gost
systemctl start gost
