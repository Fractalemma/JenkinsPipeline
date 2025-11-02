#!/bin/bash
set -euxo pipefail

# Update system
apt-get update
apt-get upgrade -y

# Install Java 17 (required for Jenkins LTS)
apt-get install -y fontconfig openjdk-17-jre

# Verify Java installation
java -version

# Install Git
apt-get install -y git

# Install Jenkins
# Add Jenkins repository key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repository
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package list and install Jenkins
apt-get update
apt-get install -y jenkins

# Start and enable Jenkins
systemctl enable jenkins
systemctl start jenkins

# Wait for Jenkins to start
sleep 30

# Install AWS CLI v2
curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt-get install -y unzip
unzip -q awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws/

# Install additional tools
apt-get install -y jq zip

# Install SSM agent (for management via Systems Manager)
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

# Set proper ownership for jenkins home
chown -R jenkins:jenkins /var/lib/jenkins

# Create helper scripts directory
mkdir -p /opt/jenkins-scripts

# Create a simple status check script
cat > /opt/jenkins-scripts/jenkins-status.sh << 'EOF'
#!/bin/bash
echo "=== Jenkins Status ==="
systemctl status jenkins --no-pager
echo ""
echo "=== Jenkins URL ==="
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "http://$INSTANCE_IP:8080"
echo ""
echo "=== Initial Admin Password ==="
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    echo "Initial Password: $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)"
else
    echo "Initial password file not found. Jenkins may not be fully initialized yet."
fi
echo ""
echo "=== Useful Commands ==="
echo "View logs: sudo journalctl -u jenkins -f"
echo "Jenkins home: /var/lib/jenkins"
echo "Restart Jenkins: sudo systemctl restart jenkins"
EOF

chmod +x /opt/jenkins-scripts/jenkins-status.sh

# Create webhook setup helper script
cat > /opt/jenkins-scripts/webhook-info.sh << 'EOF'
#!/bin/bash
JENKINS_URL="http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "=== GitHub Webhook Configuration ==="
echo "Jenkins URL: $JENKINS_URL"
echo ""
echo "Webhook Payload URL: ${JENKINS_URL}/github-webhook/"
echo ""
echo "Setup Instructions:"
echo "1. Go to your GitHub repository settings"
echo "2. Navigate to 'Webhooks' section"
echo "3. Click 'Add webhook'"
echo "4. Paste the Payload URL above"
echo "5. Set Content type to: application/json"
echo "6. Select 'Just the push event'"
echo "7. Ensure 'Active' is checked"
echo "8. Click 'Add webhook'"
EOF

chmod +x /opt/jenkins-scripts/webhook-info.sh

# Create a welcome message
cat > /etc/update-motd.d/99-jenkins-info << 'EOF'
#!/bin/bash
echo ""
echo "=========================================="
echo "    Jenkins CI/CD Server (Ubuntu 22.04)"
echo "=========================================="
echo ""
echo "Quick Commands:"
echo "  - Check Jenkins status: /opt/jenkins-scripts/jenkins-status.sh"
echo "  - Get webhook info: /opt/jenkins-scripts/webhook-info.sh"
echo ""
echo "Access Jenkins at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
EOF

chmod +x /etc/update-motd.d/99-jenkins-info

# Final setup message to system log
echo "Jenkins installation completed successfully!"
echo "Access Jenkins at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "Run '/opt/jenkins-scripts/jenkins-status.sh' to get initial admin password"
