#!/bin/bash
set -euxo pipefail

# Update system
apt update -y

# Install Java and dependencies
apt install -y fontconfig openjdk-21-jre

# Add Jenkins repository and install Jenkins
wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
apt update -y
apt install -y jenkins

systemctl enable jenkins
systemctl start jenkins

# Wait for Jenkins to start
sleep 30

# Install AWS CLI v2
curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt install -y unzip
unzip -q awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws/

# Install additional tools
apt install -y zip

# Final setup message to system log
echo "Jenkins installation completed successfully!"
echo "Access Jenkins at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
