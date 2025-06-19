#!/bin/bash

DATABASE_PASS='admin123'

# Update and install necessary packages
sudo apt update
sudo apt install -y mariadb-server git unzip

# Start and enable MariaDB
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Modify bind-address to allow remote connections
sudo sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

# Restart MariaDB to apply bind-address change
sudo systemctl restart mariadb

# Clone the vProfile project (if not already cloned)
cd /tmp/
git clone -b main https://github.com/hkhcoder/vprofile-project.git

# Set root password and secure installation
sudo mysqladmin -u root password "$DATABASE_PASS"

# Clean up default users and test DB
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
sudo mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

# Create 'accounts' DB and grant access
sudo mysql -u root -p"$DATABASE_PASS" -e "CREATE DATABASE accounts"
sudo mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'localhost' IDENTIFIED BY 'admin123'"
sudo mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%' IDENTIFIED BY 'admin123'"
sudo mysql -u root -p"$DATABASE_PASS" accounts < /tmp/vprofile-project/src/main/resources/db_backup.sql
sudo mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

# Final restart to ensure all changes take effect
sudo systemctl restart mariadb
