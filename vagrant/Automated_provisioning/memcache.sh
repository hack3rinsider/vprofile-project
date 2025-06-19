#!/bin/bash
sudo apt update
sudo apt install -y memcached

# Listen on all interfaces
sudo sed -i 's/-l 127.0.0.1/-l 0.0.0.0/' /etc/memcached.conf

sudo systemctl enable memcached
sudo systemctl restart memcached
