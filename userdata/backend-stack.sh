#!/bin/bash
DATABASE_PASS='admin123'
apt-get update -y
apt-get install -y software-properties-common
add-apt-repository -y ppa:ondrej/mariadb
apt-get update -y
apt-get install -y mariadb-server wget git unzip memcached socat

# Configure MariaDB to listen on all interfaces
sed -i 's/^bind-address/#bind-address/' /etc/mysql/mariadb.conf.d/50-server.cnf
echo "[mysqld]" >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo "bind-address = 0.0.0.0" >> /etc/mysql/mariadb.conf.d/50-server.cnf

# Start & enable mariadb-server
systemctl start mariadb
systemctl enable mariadb

# Restore the dump file for the application
cd /tmp/
wget https://raw.githubusercontent.com/devopshydclub/vprofile-repo/vp-rem/src/main/resources/db_backup.sql

# Secure MySQL installation and set up database
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DATABASE_PASS'"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
mysql -u root -p"$DATABASE_PASS" -e "CREATE DATABASE accounts"
mysql -u root -p"$DATABASE_PASS" -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin123'"
mysql -u root -p"$DATABASE_PASS" -e "CREATE USER 'admin'@'%' IDENTIFIED BY 'admin123'"
mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'localhost'"
mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%'"
mysql -u root -p"$DATABASE_PASS" accounts < /tmp/db_backup.sql
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

# Restart mariadb-server
systemctl restart mariadb

# Setup Memcached
systemctl start memcached
systemctl enable memcached
memcached -p 11211 -U 11111 -u memcache -d
sleep 30

# Install RabbitMQ
apt-get install -y curl gnupg
curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | apt-key add -
echo "deb https://dl.bintray.com/rabbitmq-erlang/debian focal erlang" | tee /etc/apt/sources.list.d/rabbitmq.list
apt-get update -y
apt-get install -y rabbitmq-server
systemctl start rabbitmq-server
systemctl enable rabbitmq-server
echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config
rabbitmqctl add_user test test
rabbitmqctl set_user_tags test administrator
rabbitmqctl set_permissions -p / test ".*" ".*" ".*"
systemctl restart rabbitmq-server
