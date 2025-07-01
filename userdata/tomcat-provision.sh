#!/bin/bash
set -e  # Exit immediately on any error

# Update and install core packages
sudo apt update
sudo apt install -y openjdk-8-jdk git wget unzip curl

# Install AWS CLI v2 (since awscli is not in apt on 24.04+)
cd /tmp
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install || true  # tolerate if already installed

# Create tomcat user if it doesn't exist
sudo useradd --system --shell /usr/sbin/nologin --home /usr/local/tomcat8 tomcat || true

# Download and extract Tomcat
TOMURL="https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.37/bin/apache-tomcat-8.5.37.tar.gz"
cd /tmp
wget -q "$TOMURL" -O tomcat.tar.gz
tar -xzf tomcat.tar.gz
TOMDIR=$(tar -tf tomcat.tar.gz | head -1 | cut -d '/' -f1)

# Move Tomcat to target directory
sudo mkdir -p /usr/local/tomcat8
sudo rsync -a "/tmp/$TOMDIR/" /usr/local/tomcat8/

# Configure tomcat-users.xml
sudo tee /usr/local/tomcat8/conf/tomcat-users.xml > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
  <role rolename="manager-gui"/>
  <role rolename="manager-script"/>
  <user username="tomcat" password="admin123" roles="manager-gui,manager-script"/>
</tomcat-users>
EOF

# Allow manager access from all IPs
sudo mkdir -p /usr/local/tomcat8/webapps/manager/META-INF/
sudo tee /usr/local/tomcat8/webapps/manager/META-INF/context.xml > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true" />
EOF

# Set ownership
sudo chown -R tomcat:tomcat /usr/local/tomcat8

# Create systemd service
sudo tee /etc/systemd/system/tomcat.service > /dev/null <<EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=simple
User=tomcat
Group=tomcat
Environment=CATALINA_HOME=/usr/local/tomcat8
Environment=CATALINA_BASE=/usr/local/tomcat8
ExecStart=/usr/local/tomcat8/bin/catalina.sh run
ExecStop=/usr/local/tomcat8/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start Tomcat
sudo systemctl daemon-reload
sudo systemctl enable --now tomcat

# Optional: verify port 8080 is open (can be logged in cloud-init)
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080 || true
