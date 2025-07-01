#!/bin/bash

set -e  # Exit on any error

# Update package lists
sudo apt update -y

# Install Java 17 (preferred for Jenkins on Ubuntu 22.04+)
sudo apt install -y openjdk-17-jdk

# Verify Java version
java -version

# Install Maven (optional, only if needed for builds)
sudo apt install -y maven

# Add Jenkins GPG key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins apt repository
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update again after adding Jenkins repo
sudo apt update -y

# Install Jenkins
sudo apt install -y jenkins

# Enable and start Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Check Jenkins service status
sudo systemctl status jenkins --no-pager

# Optional: Open port 8080 in firewall (only if UFW is enabled)
# sudo ufw allow 8080
# sudo ufw reload

# Print initial admin password
echo "Jenkins installed. Initial admin password is:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

