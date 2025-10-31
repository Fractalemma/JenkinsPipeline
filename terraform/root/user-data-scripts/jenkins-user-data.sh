#!/bin/bash
set -euxo pipefail

# Update system
yum update -y

# Install Java 17 (required for Jenkins)
amazon-linux-extras install -y java-openjdk11
yum install -y java-17-amazon-corretto-devel
alternatives --set java /usr/lib/jvm/java-17-amazon-corretto.x86_64/bin/java

# Install Git
yum install -y git

# Install Node.js and npm (for building the Vite app)
# Install required dependencies for Node.js
yum install -y gcc-c++ make libatomic

# Install Docker (for potential future use)
yum install -y docker
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user

# Install Jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum upgrade -y
yum install -y jenkins

# Configure Jenkins
systemctl enable jenkins
systemctl start jenkins

# Wait for Jenkins to start
sleep 30

# Now that Jenkins user exists, install Node.js for jenkins user
# Install nvm for the jenkins user
su - jenkins -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'

# Source nvm and install Node.js for jenkins user
su - jenkins -c '
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
unzip -q awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws/

# Install additional tools
yum install -y unzip jq zip

# Ensure SSM agent is running (for management)
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Create Jenkins configuration directory
mkdir -p /var/lib/jenkins/init.groovy.d

# Create initial admin user and disable setup wizard
cat > /var/lib/jenkins/init.groovy.d/01-create-admin-user.groovy << 'EOF'
#!groovy
import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

// Create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin123!")
instance.setSecurityRealm(hudsonRealm)

// Set authorization strategy
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Disable setup wizard
instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)

// Save configuration
instance.save()
EOF

# Install required Jenkins plugins
cat > /var/lib/jenkins/init.groovy.d/02-install-plugins.groovy << 'EOF'
#!groovy
import jenkins.model.Jenkins
import hudson.model.UpdateCenter
import java.util.logging.Logger

def logger = Logger.getLogger("")
def installed = false
def initialized = false

def pluginParameter = [
    "git",
    "workflow-aggregator",
    "pipeline-stage-view",
    "blueocean",
    "github",
    "github-branch-source",
    "pipeline-github-lib",
    "aws-credentials",
    "pipeline-aws",
    "nodejs"
]

def instance = Jenkins.getInstance()
def pm = instance.getPluginManager()
def uc = instance.getUpdateCenter()

pluginParameter.each { plugin ->
    if (!pm.getPlugin(plugin)) {
        logger.info("Installing plugin: $${plugin}")
        def installFuture = uc.getPlugin(plugin).deploy()
        while(!installFuture.isDone()) {
            sleep(3000)
        }
        installed = true
    }
}

if (installed) {
    logger.info("Plugins installed, restarting Jenkins")
    instance.safeRestart()
}
EOF

# Create Jenkins job configuration
mkdir -p /var/lib/jenkins/jobs/deploy-vite-app
cat > /var/lib/jenkins/jobs/deploy-vite-app/config.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1316.vd2290d3341a_f">
  <actions/>
  <description>Automated deployment pipeline for Vite application</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.37.3.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@3695.v8edf05badc9b_">
    <script>pipeline {
    agent any
    
    environment {
        REGION = '${region}'
        BUCKET = '${bucket_name}'
        KEY_PREFIX = 'myapp/releases'
        APP_TAG_KEY = '${app_tag_key}'
        APP_TAG_VAL = '${app_tag_value}'
    }
    
    stages {
        stage('Setup Node.js') {
            steps {
                script {
                    sh '''
                        export NVM_DIR="$HOME/.nvm"
                        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                        nvm use 18
                        echo "Node version: $(node --version)"
                        echo "NPM version: $(npm --version)"
                    '''
                }
            }
        }
        
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                dir('my-vite-app') {
                    sh '''
                        export NVM_DIR="$HOME/.nvm"
                        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                        nvm use 18
                        npm install
                    '''
                }
            }
        }
        
        stage('Build') {
            steps {
                dir('my-vite-app') {
                    sh '''
                        export NVM_DIR="$HOME/.nvm"
                        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                        nvm use 18
                        npm run build
                    '''
                }
            }
        }
        
        stage('Package Artifact') {
            steps {
                script {
                    def timestamp = new Date().format("yyyy-MM-dd'T'HH-mm-ss")
                    env.RELEASE_NAME = "$${timestamp}_$${env.BUILD_NUMBER}"
                    env.S3_KEY = "$${env.KEY_PREFIX}/$${env.RELEASE_NAME}.zip"
                    
                    dir('my-vite-app') {
                        sh "cd dist && zip -r ../artifact.zip ."
                    }
                }
            }
        }
        
        stage('Upload to S3') {
            steps {
                script {
                    sh """
                        aws s3 cp my-vite-app/artifact.zip s3://$${env.BUCKET}/$${env.S3_KEY} --region $${env.REGION}
                        echo "Uploaded to s3://$${env.BUCKET}/$${env.S3_KEY}"
                    """
                }
            }
        }
        
        stage('Deploy via SSM') {
            steps {
                script {
                    sh """
                        CMD_ID=\$$(aws ssm send-command \\
                            --region $${env.REGION} \\
                            --document-name "AWS-RunShellScript" \\
                            --targets "Key=tag:$${env.APP_TAG_KEY},Values=$${env.APP_TAG_VAL}" \\
                            --comment "Jenkins deploy $${env.RELEASE_NAME}" \\
                            --parameters commands="sudo /opt/deploy/pull_and_switch.sh $${env.BUCKET} $${env.S3_KEY}" \\
                            --query "Command.CommandId" --output text)
                        
                        echo "SSM Command ID: \$$CMD_ID"
                        
                        # Wait for completion
                        STATUS="InProgress"
                        ATTEMPTS=0
                        MAX_ATTEMPTS=120
                        
                        while [ "\$$STATUS" = "InProgress" ] && [ \$$ATTEMPTS -le \$$MAX_ATTEMPTS ]; do
                            sleep 5
                            STATUS=\$$(aws ssm list-command-invocations --region $${env.REGION} \\
                                --command-id \$$CMD_ID --details \\
                                --query "CommandInvocations[0].Status" --output text 2>/dev/null || echo "InProgress")
                            echo "SSM Status: \$$STATUS (attempt \$$ATTEMPTS/\$$MAX_ATTEMPTS)"
                            ATTEMPTS=\$$((ATTEMPTS + 1))
                        done
                        
                        if [ "\$$STATUS" != "Success" ]; then
                            echo "Deployment failed with status: \$$STATUS"
                            aws ssm list-command-invocations --region $${env.REGION} \\
                                --command-id \$$CMD_ID --details \\
                                --query "CommandInvocations[0].CommandPlugins[0].Output" --output text
                            exit 1
                        fi
                        
                        echo "Deployment completed successfully!"
                    """
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}</script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

# Configure Jenkins system settings
cat > /var/lib/jenkins/init.groovy.d/03-configure-system.groovy << 'EOF'
#!groovy
import jenkins.model.*

def instance = Jenkins.getInstance()

// Basic system configuration
instance.setNumExecutors(2)
instance.setQuietPeriod(5)
instance.setScmCheckoutRetryCount(3)

// Save configuration
instance.save()
EOF

# Set proper ownership
chown -R jenkins:jenkins /var/lib/jenkins

# Restart Jenkins to apply all configurations
systemctl restart jenkins

# Wait for Jenkins to be ready
sleep 60

# Create webhook script for GitHub integration
cat > /opt/setup-github-webhook.sh << 'EOF'
#!/bin/bash
# This script helps setup GitHub webhook
# Run this script after configuring your GitHub repository

JENKINS_URL="http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "Jenkins is available at: $$JENKINS_URL"
echo "Default credentials: admin / admin123!"
echo ""
echo "To setup GitHub webhook:"
echo "1. Go to your GitHub repository settings"
echo "2. Click on 'Webhooks' in the left sidebar"
echo "3. Click 'Add webhook'"
echo "4. Set Payload URL to: $${JENKINS_URL}/github-webhook/"
echo "5. Set Content type to: application/json"
echo "6. Select 'Just the push event'"
echo "7. Check 'Active'"
echo "8. Click 'Add webhook'"
echo ""
echo "Job URL: $${JENKINS_URL}/job/deploy-vite-app/"
EOF

chmod +x /opt/setup-github-webhook.sh

# Create a simple status check script
cat > /opt/jenkins-status.sh << 'EOF'
#!/bin/bash
echo "=== Jenkins Status ==="
systemctl status jenkins --no-pager
echo ""
echo "=== Jenkins URL ==="
echo "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
echo "=== Credentials ==="
echo "Username: admin"
echo "Password: admin123!"
echo ""
echo "=== Logs ==="
echo "To view logs: sudo journalctl -u jenkins -f"
echo "Jenkins home: /var/lib/jenkins"
EOF

chmod +x /opt/jenkins-status.sh

# Final setup message
echo "Jenkins setup completed!"
echo "Access Jenkins at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "Default credentials: admin / admin123!"
echo "Run '/opt/jenkins-status.sh' to check status"
echo "Run '/opt/setup-github-webhook.sh' for webhook setup instructions"
