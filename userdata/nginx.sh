#!/bin/bash

# Install nginx
sudo apt update
sudo apt install -y nginx

# Create vproapp reverse proxy config
cat <<EOT | sudo tee /etc/nginx/sites-available/vproapp
upstream vproapp {
    server app01:8080;
}

server {
    listen 80;

    location / {
        proxy_pass http://vproapp;
    }
}
EOT

# Enable the new config
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/vproapp /etc/nginx/sites-enabled/vproapp

# Start and enable nginx
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl restart nginx
