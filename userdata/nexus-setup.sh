#!/bin/bash

# System Update & Dependencies
apt update -y && apt install openjdk-8-jdk wget tar net-tools curl -y

# Create nexus user if not exists
id nexus &>/dev/null || useradd -M -d /opt/nexus -s /bin/false nexus

# Create required directories
mkdir -p /opt/nexus /opt/sonatype-work
cd /tmp

# Download and extract Nexus
wget -q https://download.sonatype.com/nexus/3/nexus-3.81.1-01-linux-x86_64.tar.gz -O nexus.tar.gz
tar -xzf nexus.tar.gz

# Move content to /opt/nexus
mv nexus-3.81.1-01/* /opt/nexus/
rm -rf nexus-3.81.1-01

# Set ownership
chown -R nexus:nexus /opt/nexus /opt/sonatype-work

# Set nexus run user
echo 'run_as_user="nexus"' > /opt/nexus/bin/nexus.rc

# Set low-memory JVM options
sed -i 's/-Xms.*/-Xms512m/' /opt/nexus/bin/nexus.vmoptions
sed -i 's/-Xmx.*/-Xmx768m/' /opt/nexus/bin/nexus.vmoptions

# Systemd service
cat <<EOF > /etc/systemd/system/nexus.service
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Start Nexus
systemctl daemon-reload
systemctl enable nexus
systemctl start nexus
