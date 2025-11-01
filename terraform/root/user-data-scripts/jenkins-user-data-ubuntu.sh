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

# Install Docker (for potential future use)
apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl enable docker
systemctl start docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

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

# Wait for Jenkins to start and create user
sleep 30

# Install Node.js for Jenkins user
# Install NVM for jenkins user
su - jenkins -s /bin/bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'

# Source nvm and install Node.js 18 for jenkins user
su - jenkins -s /bin/bash -c '
export NVM_DIR="/var/lib/jenkins/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 18
nvm use 18
nvm alias default 18
'

# Create a script to ensure Node.js is available in Jenkins PATH
cat > /var/lib/jenkins/.profile << 'EOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
export PATH="$NVM_DIR/versions/node/$(nvm current)/bin:$PATH"
EOF

# Also add to .bashrc for jenkins user
cat >> /var/lib/jenkins/.bashrc << 'EOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
export PATH="$NVM_DIR/versions/node/$(nvm current)/bin:$PATH"
EOF

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
