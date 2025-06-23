#!/bin/bash

#------------------------#
# System Configuration   #
#------------------------#

# Backup system files
cp /etc/sysctl.conf /root/sysctl.conf_backup
cp /etc/security/limits.conf /root/sec_limit.conf_backup

# Apply kernel parameters
cat <<EOF | tee -a /etc/sysctl.conf
vm.max_map_count=262144
fs.file-max=65536
EOF
sysctl -p

# Configure limits
cat <<EOF | tee -a /etc/security/limits.conf
sonar   -   nofile   65536
sonar   -   nproc    4096
EOF

#------------------------#
# Install Java (OpenJDK) #
#------------------------#
apt update -y
apt install -y openjdk-11-jdk unzip curl gnupg2 ca-certificates lsb-release net-tools ufw nginx

#---------------------------#
# Install & Configure PostgreSQL #
#---------------------------#

# Add PostgreSQL APT repository
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list

apt update -y
apt install -y postgresql postgresql-contrib

systemctl enable postgresql
systemctl start postgresql
echo "postgres:admin123" | chpasswd

# Create sonar DB and user
sudo -u postgres psql <<EOF
CREATE USER sonar WITH ENCRYPTED PASSWORD 'admin123';
CREATE DATABASE sonarqube OWNER sonar;
GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;
EOF

#------------------------#
# Install SonarQube      #
#------------------------#
mkdir -p /opt/sonarqube
cd /opt
curl -O https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-8.3.0.34182.zip
unzip -q sonarqube-8.3.0.34182.zip
mv sonarqube-8.3.0.34182/* sonarqube/
rm -rf sonarqube-8.3.0.34182 sonarqube-8.3.0.34182.zip

# Create sonar user
groupadd sonar
useradd -c "SonarQube User" -d /opt/sonarqube -g sonar sonar
chown -R sonar:sonar /opt/sonarqube

# Configure sonar.properties
cp /opt/sonarqube/conf/sonar.properties /root/sonar.properties.bak
cat <<EOF > /opt/sonarqube/conf/sonar.properties
sonar.jdbc.username=sonar
sonar.jdbc.password=admin123
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube

sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.web.javaAdditionalOpts=-server
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:+HeapDumpOnOutOfMemoryError
sonar.log.level=INFO
sonar.path.logs=logs
EOF

#-----------------------------#
# Setup systemd for SonarQube #
#-----------------------------#
cat <<EOF > /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube Service
After=syslog.target network.target postgresql.service

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonar
Group=sonar
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sonarqube.service

#----------------------#
# Configure Nginx      #
#----------------------#
rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default

cat <<EOF > /etc/nginx/sites-available/sonarqube
server {
    listen 80;
    server_name sonarqube.groophy.in;

    access_log  /var/log/nginx/sonar.access.log;
    error_log   /var/log/nginx/sonar.error.log;

    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    location / {
        proxy_pass http://127.0.0.1:9000;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_redirect off;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;
    }
}
EOF

ln -s /etc/nginx/sites-available/sonarqube /etc/nginx/sites-enabled/sonarqube
systemctl enable nginx.service

#---------------------#
# Firewall & Reboot   #
#---------------------#
#ufw allow 22
#ufw allow 80
#ufw allow 9000
#ufw --force enable

# Start services
systemctl start postgresql
systemctl start sonarqube.service
systemctl start nginx.service

echo "Setup complete. Rebooting in 30 seconds..."
sleep 30
reboot
