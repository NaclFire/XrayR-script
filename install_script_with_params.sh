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
if [ -z "$1" ]; then
    read -p "Enter XrayR API Host (e.g., http://127.0.0.1:667): " api_host
else
    api_host="$1"
fi

if [ -z "$2" ]; then
    read -p "Enter XrayR API Key (e.g., 123): " api_key
else
    api_key="$2"
fi

if [ -z "$3" ]; then
    read -p "Enter XrayR Node ID (e.g., 41): " node_id
else
    node_id="$3"
fi

# Update XrayR configuration file
sed -i "s#^\\s*ApiHost:.*#      ApiHost: \"${api_host}\"#" /etc/XrayR/config.yml
sed -i "s#^\\s*ApiKey:.*#      ApiKey: \"${api_key}\"#" /etc/XrayR/config.yml
sed -i "s#^\\s*NodeID:.*#      NodeID: ${node_id}#" /etc/XrayR/config.yml

# Change CertMode to none in the XrayR configuration file
sed -i "s#^\\s*CertMode:.*#        CertMode: none,#" /etc/XrayR/config.yml

# Start XrayR
systemctl start XrayR

# Check and enable BBR
kernel_version=$(uname -r)
if [[ $(echo ${kernel_version} | awk -F'.' '{print $1}') -ge "5" ]]; then
    echo "net.core.default_qdisc=cake" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
else
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
fi
sysctl -p
echo -e "${Info}BBR启动成功！"

# Install gost
mkdir gost && cd gost
wget -N --no-check-certificate https://github.com/ginuerzh/gost/releases/download/v2.11.1/gost-linux-amd64-2.11.1.gz
gzip -d gost-linux-amd64-2.11.1.gz
mv gost-linux-amd64-2.11.1 gost
chmod +x gost

# Read user input for gost configuration
if [ -z "$4" ]; then
    read -p "Enter the relay+tls port (e.g., 10165): " relay_port
else
    relay_port="$4"
fi

if [ -z "$5" ]; then
    read -p "Enter the local port (e.g., 10166): " local_port
else
    local_port="$5"
fi

# Create gost.json file
cat <<EOF > gost.json
{
  "Retries": 0,
  "ServeNodes": [],
  "ChainNodes": [],
  "Routes": [
    {
      "ServeNodes": [
        "relay+tls://:${relay_port}/127.0.0.1:${local_port}"
      ],
      "ChainNodes": []
    }
  ]
}
EOF

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
