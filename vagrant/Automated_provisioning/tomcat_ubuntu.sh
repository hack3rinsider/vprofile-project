#!/bin/bash

TOMURL="https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.75/bin/apache-tomcat-9.0.75.tar.gz"

sudo apt update
sudo apt install -y openjdk-11-jdk git maven wget

cd /tmp/
wget $TOMURL -O tomcat.tar.gz
tar xzvf tomcat.tar.gz
TOMDIR=$(tar tf tomcat.tar.gz | head -1 | cut -f1 -d"/")

# Create tomcat user
sudo useradd -r -s /bin/false tomcat

# Move tomcat files
sudo rsync -avzh /tmp/$TOMDIR/ /opt/tomcat/
sudo chown -R tomcat:tomcat /opt/tomcat

# Systemd service
sudo tee /etc/systemd/system/tomcat.service <<EOT
[Unit]
Description=Apache Tomcat
After=network.target

[Service]
User=tomcat
Group=tomcat
WorkingDirectory=/opt/tomcat
ExecStart=/opt/tomcat/bin/catalina.sh run
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOT

# Reload and start
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now tomcat

# Deploy app
cd /tmp/
git clone -b main https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project
mvn clean install

sudo systemctl stop tomcat
sudo rm -rf /opt/tomcat/webapps/ROOT*
sudo cp target/vprofile-v2.war /opt/tomcat/webapps/ROOT.war
sudo chown -R tomcat:tomcat /opt/tomcat/webapps
sudo systemctl start tomcat
