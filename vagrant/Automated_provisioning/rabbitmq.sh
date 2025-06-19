#!/bin/bash

# Remove packagecloud.io RabbitMQ repo (if it exists)
sudo rm -f /etc/apt/sources.list.d/rabbitmq.list
sudo rm -f /usr/share/keyrings/rabbitmq-archive-keyring.gpg

# Update system and install RabbitMQ from Ubuntu's own repo
sudo apt update
sudo apt install -y rabbitmq-server

# Enable and start RabbitMQ
sudo systemctl enable rabbitmq-server
sudo systemctl start rabbitmq-server

# Allow remote access (disable loopback restriction)
sudo mkdir -p /etc/rabbitmq
echo '[{rabbit, [{loopback_users, []}]}].' | sudo tee /etc/rabbitmq/rabbitmq.config

# Create a test user with admin rights
sudo rabbitmqctl add_user test test
sudo rabbitmqctl set_user_tags test administrator

# Restart RabbitMQ to apply changes
sudo systemctl restart rabbitmq-server
