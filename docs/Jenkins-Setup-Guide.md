# Jenkins Setup Guide

This guide provides step-by-step instructions for setting up Jenkins on Ubuntu 22.04 LTS, creating a deployment pipeline job, and configuring GitHub webhooks for automated deployments.

## Table of Contents

1. [Initial Jenkins Setup](#initial-jenkins-setup)
2. [Install Required Plugins](#install-required-plugins)
3. [Configure Jenkins System Settings](#configure-jenkins-system-settings)
4. [Create GitHub Personal Access Token](#create-github-personal-access-token)
5. [Create the Pipeline Job](#create-the-pipeline-job)
6. [Configure GitHub Webhook](#configure-github-webhook)
7. [Test the Pipeline](#test-the-pipeline)
8. [Troubleshooting](#troubleshooting)

---

## Initial Jenkins Setup

### 1. Access Jenkins

After Terraform deploys the Jenkins EC2 instance, access Jenkins through your browser:

```bash
http://<JENKINS_EC2_PUBLIC_IP>:8080
```

You can get the public IP from:

- AWS Console (EC2 > Instances)
- Terraform outputs (if configured)
- SSM Session: Run `/opt/jenkins-scripts/jenkins-status.sh`

### 2. Unlock Jenkins

Jenkins will prompt you for an initial admin password.

**To retrieve the password:**

Option A - Via SSM Session:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Option B - Via helper script:

```bash
/opt/jenkins-scripts/jenkins-status.sh
```

Copy the password and paste it into the Jenkins web interface.

### 3. Customize Jenkins

When prompted "Customize Jenkins":

- **Select**: "Install suggested plugins"
- Wait for the plugins to install (this may take 3-5 minutes)

### 4. Create First Admin User

Fill in the form to create your admin user:

- **Username**: Choose a username (e.g., `admin`)
- **Password**: Choose a strong password
- **Full name**: Your name
- **Email**: Your email address

Click **Save and Continue**.

### 5. Instance Configuration

- **Jenkins URL**: Should be auto-filled as `http://<PUBLIC_IP>:8080/`
- Verify it's correct and click **Save and Finish**
- Click **Start using Jenkins**

---

## Install Required Plugins

Our pipeline requires additional plugins beyond the suggested ones.

### 1. Navigate to Plugin Manager

1. From Jenkins Dashboard, click **Manage Jenkins** (left sidebar)
2. Click **Manage Plugins** (or **Plugins** in newer versions)
3. Click on the **Available plugins** tab

### 2. Search and Install Plugins

Search for and select the following plugins:

#### Essential Plugins

- **Git plugin** (usually already installed)
- **GitHub plugin**
- **GitHub Branch Source plugin**
- **Pipeline: AWS Steps** (for AWS CLI operations)
- **Pipeline** (usually already installed)
- **Pipeline: Stage View**

#### Optional but Recommended

- **Blue Ocean** (modern UI for pipelines)
- **AnsiColor** (colored console output)

### 3. Install Plugins

1. Check the box next to each plugin you want to install
2. Click **Install without restart** (or **Download now and install after restart**)
3. On the installation page, optionally check **Restart Jenkins when installation is complete and no jobs are running**
4. Wait for installation to complete

---

## Configure Jenkins System Settings

### 1. Configure Global Tool Configuration (Optional)

If you want to configure Node.js globally:

1. Go to **Manage Jenkins** > **Global Tool Configuration**
2. Scroll to **NodeJS** section
3. Click **Add NodeJS**
   - **Name**: `Node 18`
   - **Version**: Select `18.x`
   - Click **Save**

*Note: Our pipeline uses NVM installed in the user-data script, so this is optional.*

### 2. Configure System Settings

1. Go to **Manage Jenkins** > **System**
2. Configure the following:

#### GitHub Servers Section

- **GitHub Server**: Should have a default GitHub server
- If not present, add one:
  - Click **Add GitHub Server**
  - **Name**: `GitHub`
  - **API URL**: `https://api.github.com` (default)
  - Leave credentials blank for now (we'll use webhook)

Click **Save** at the bottom.

---

## Create GitHub Personal Access Token

You'll need a GitHub Personal Access Token (PAT) to allow Jenkins to access your repository.

### 1. Generate Token on GitHub

1. Go to GitHub.com and log in
2. Click your **profile picture** (top right) > **Settings**
3. Scroll down and click **Developer settings** (bottom left)
4. Click **Personal access tokens** > **Tokens (classic)**
5. Click **Generate new token** > **Generate new token (classic)**

### 2. Configure Token

- **Note**: `Jenkins CI/CD Access`
- **Expiration**: Choose appropriate expiration (e.g., 90 days)
- **Select scopes**:
  - ✅ `repo` (all sub-options)
  - ✅ `admin:repo_hook` (all sub-options)

Click **Generate token**

### 3. Save Token

**IMPORTANT**: Copy the token immediately. You won't be able to see it again!

Save it securely (e.g., password manager).

---

## Create the Pipeline Job

### 1. Create New Item

1. From Jenkins Dashboard, click **New Item** (top left)
2. **Enter an item name**: `deploy-vite-app` (or your preferred name)
3. Select **Pipeline**
4. Click **OK**

### 2. General Configuration

In the job configuration page:

#### Description (Optional)

```text
Automated deployment pipeline for Vite application to AWS via S3 and SSM
```

#### GitHub Project (Optional)

- ✅ Check **GitHub project**
- **Project url**: `https://github.com/<YOUR_USERNAME>/<YOUR_REPO>/`

### 3. Build Triggers

This section determines when the pipeline runs.

#### For Automated Deployments (Webhook)

- ✅ Check **GitHub hook trigger for GITScm polling**
  - This enables the pipeline to trigger automatically when GitHub sends a webhook
  - No additional configuration needed here
  - The actual webhook will be configured on GitHub (next section)

#### Alternative Options (choose based on your needs)

**Option A - Poll SCM** (not recommended for production):

- ✅ Check **Poll SCM**
- **Schedule**: `H/5 * * * *` (polls every 5 minutes)
- *Note*: Uses more resources, delays are longer

**Option B - Build periodically** (for scheduled builds):

- ✅ Check **Build periodically**
- **Schedule**: Use cron syntax (e.g., `H 2 * * *` for daily at 2 AM)

**Option C - Manual only**:

- Leave all triggers unchecked
- Builds only when manually triggered

**Recommended**: Use **GitHub hook trigger for GITScm polling** for instant deployments.

### 4. Advanced Project Options (Optional)

You can configure these if needed:

- **Display Name**: Custom display name for the job
- **Quiet period**: Seconds to wait before starting build (default: 5)
- **Retry Count**: Number of times to retry checkout (default: 0)

### 5. Pipeline Configuration

This is where you define your pipeline script.

#### Pipeline Definition

- Select **Pipeline script** (not Pipeline script from SCM)

#### Script

Copy the entire contents of the `Jenkinsfile` into the script text area.

**Location of Jenkinsfile**: `terraform/root/user-data-scripts/Jenkinsfile`

The script should start with:

```groovy
pipeline {
    agent any
    
    environment {
        REGION = 'us-east-1'
        BUCKET = 'jenkins-pipeline-emmanuel-engineering-com'
        ...
```

**Important**: Update these environment variables to match your setup:

```groovy
environment {
    REGION = 'us-east-1'                                    // Your AWS region
    BUCKET = 'jenkins-pipeline-emmanuel-engineering-com'    // Your S3 bucket name
    KEY_PREFIX = 'myapp/releases'                           // S3 prefix for artifacts
    APP_TAG_KEY = 'Role'                                    // Tag key for target instances
    APP_TAG_VAL = 'App'                                     // Tag value for target instances
}
```

#### Pipeline Options

Below the script area, you may see:

- ✅ **Use Groovy Sandbox** (should be checked)
  - Allows the script to run with restricted permissions (safer)
  - Uncheck only if you need unrestricted access and understand the risks

### 6. Save the Job

Click **Save** at the bottom of the page.

---

## Configure GitHub Webhook

Now we'll configure GitHub to automatically trigger the Jenkins pipeline on push events.

### 1. Navigate to Repository Settings

1. Go to your GitHub repository
2. Click **Settings** (top tab)
3. Click **Webhooks** (left sidebar)
4. Click **Add webhook**

### 2. Configure Webhook

#### Payload URL

```text
http://<JENKINS_EC2_PUBLIC_IP>:8080/github-webhook/
```

#### Important Notes

- Replace `<JENKINS_EC2_PUBLIC_IP>` with your Jenkins server's public IP
- The trailing `/` in `/github-webhook/` is **required**
- Use `http://` not `https://` (unless you've configured SSL)

**To get the exact URL**, you can run on the Jenkins EC2:

```bash
/opt/jenkins-scripts/webhook-info.sh
```

#### Content type

- Select **application/json**

#### Secret (Optional but Recommended)

- Leave blank for now
- For production, generate a secret token and configure it in both Jenkins and GitHub

#### SSL verification

- Select **Enable SSL verification** (if using HTTPS)
- Select **Disable SSL verification** (if using HTTP - not recommended for production)

#### Which events would you like to trigger this webhook?

Select one of:

**Option A - Just the push event** (Recommended)

- ⚪ Select **Just the push event**
- Pipeline triggers on every push to the repository

**Option B - Let me select individual events**

- ⚪ Select **Let me select individual events**
- Check boxes:
  - ✅ **Pushes**
  - ✅ **Pull requests** (if you want to test PRs)

**Option C - Send me everything**

- Not recommended (too noisy)

#### Active

- ✅ Ensure **Active** is checked

### 3. Add Webhook

Click **Add webhook**

### 4. Verify Webhook

After adding:

1. GitHub will send a test ping to Jenkins
2. You should see a green checkmark ✅ next to the webhook
3. If you see a red ❌, click on the webhook to view the error details

**Common Issues**:
- Jenkins server not accessible from internet (check Security Group)
- Incorrect URL (missing trailing slash)
- Jenkins not running

---

## Test the Pipeline

### Test 1: Manual Trigger

1. Go to Jenkins Dashboard
2. Click on your job (`deploy-vite-app`)
3. Click **Build Now** (left sidebar)
4. Watch the build progress in **Build History**
5. Click on the build number (e.g., `#1`)
6. Click **Console Output** to see logs

**Expected Result**: Pipeline should complete successfully

### Test 2: Automatic Trigger (Webhook)

1. Make a small change to your repository (e.g., update README)
2. Commit and push to GitHub:
   ```bash
   git add .
   git commit -m "Test webhook trigger"
   git push
   ```
3. Go to Jenkins Dashboard
4. Within a few seconds, you should see a new build starting automatically

**Expected Result**: Build triggers automatically on push

### Test 3: Verify Deployment

After a successful build:

1. Check the Console Output for the deployment log
2. Access your application via the ALB URL
3. Verify the new version is deployed

---

## Troubleshooting

### Jenkins Won't Start

**Symptoms**: Can't access Jenkins web interface

**Solutions**:
```bash
# Check Jenkins status
sudo systemctl status jenkins

# Check logs
sudo journalctl -u jenkins -n 50

# Restart Jenkins
sudo systemctl restart jenkins

# Check Java version
java -version  # Should be Java 17
```

### Webhook Not Triggering Builds

**Check Security Group**:
- Ensure port 8080 is open to GitHub's webhook IPs
- For testing, you can temporarily allow 0.0.0.0/0 (⚠️ not for production)

**Check Jenkins GitHub Plugin**:
1. Go to **Manage Jenkins** > **System Log**
2. Look for webhook-related errors

**Check GitHub Webhook Delivery**:
1. Go to GitHub repository > Settings > Webhooks
2. Click on your webhook
3. Scroll to **Recent Deliveries**
4. Click on a delivery to see the request and response
5. Check for errors (should be `200 OK`)

### Pipeline Fails at "Setup Node.js" Stage

**Issue**: NVM or Node.js not found

**Solution**:
```bash
# SSH into Jenkins EC2
# Check if NVM is installed for jenkins user
sudo su - jenkins
nvm --version
node --version

# If not installed, reinstall:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 18
```

### Pipeline Fails at "Deploy via SSM" Stage

**Common Causes**:

1. **IAM Permissions**: Jenkins EC2 doesn't have permission to use SSM
   - Check IAM instance profile attached to Jenkins EC2
   - Verify it has `ssm:SendCommand` and `ssm:ListCommandInvocations` permissions

2. **Target Instances Not Found**:
   - Verify app EC2 instances have the correct tags (`Role=App`)
   - Verify SSM agent is running on target instances

3. **Script Not Found on Target**:
   - Verify `/opt/deploy/pull_and_switch.sh` exists on target instances
   - Check it's executable: `sudo chmod +x /opt/deploy/pull_and_switch.sh`

**Debug Commands**:
```bash
# From Jenkins EC2, test SSM access
aws ssm describe-instance-information --region us-east-1

# Check if target instances are visible
aws ssm send-command \
  --region us-east-1 \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:Role,Values=App" \
  --parameters 'commands=["echo test"]'
```

### Build Fails at "Upload to S3" Stage

**Issue**: AWS credentials or permissions

**Solution**:
- Verify Jenkins EC2 has IAM permissions to write to S3 bucket
- Check bucket name is correct in pipeline environment variables
- Test S3 access manually:
  ```bash
  sudo su - jenkins
  echo "test" > test.txt
  aws s3 cp test.txt s3://YOUR-BUCKET/test.txt --region us-east-1
  ```

### "Error: Workspace is dirty" or Git Issues

**Issue**: Git repository state issues

**Solution**:
- The pipeline has `cleanWs()` in the post section
- If issues persist, you can manually clean:
  ```bash
  sudo su - jenkins
  cd /var/lib/jenkins/workspace/deploy-vite-app
  git clean -fdx
  ```

---

## Additional Configuration

### Enable Build Notifications (Optional)

Configure email notifications:

1. **Manage Jenkins** > **System**
2. Scroll to **E-mail Notification**
3. Configure SMTP server
4. Add to pipeline post section:
   ```groovy
   post {
       success {
           mail to: 'team@example.com',
                subject: "Deployment Successful: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Good news! Deployment completed successfully."
       }
       failure {
           mail to: 'team@example.com',
                subject: "Deployment Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Deployment failed. Check Jenkins for details."
       }
   }
   ```

### Secure Jenkins (Production)

1. **Enable HTTPS**:
   - Use a reverse proxy (nginx) with SSL certificate
   - Or configure Jenkins with a Java keystore

2. **Configure Security Realm**:
   - **Manage Jenkins** > **Security**
   - Configure proper authentication (LDAP, SAML, etc.)

3. **Restrict Permissions**:
   - Use Matrix-based security
   - Create role-based access control

4. **Regular Backups**:
   - Backup `/var/lib/jenkins` directory regularly
   - Consider using ThinBackup plugin

---

## Useful Jenkins Commands

```bash
# Restart Jenkins
sudo systemctl restart jenkins

# Stop Jenkins
sudo systemctl stop jenkins

# Start Jenkins
sudo systemctl start jenkins

# View logs
sudo journalctl -u jenkins -f

# Check Jenkins status
/opt/jenkins-scripts/jenkins-status.sh

# Get webhook info
/opt/jenkins-scripts/webhook-info.sh

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## Next Steps

1. ✅ Complete initial Jenkins setup
2. ✅ Install required plugins
3. ✅ Create and configure pipeline job
4. ✅ Set up GitHub webhook
5. ✅ Test manual and automatic deployments
6. 🔄 Monitor builds and deployments
7. 🔄 Optimize pipeline as needed
8. 🔄 Implement security best practices

---

## Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [GitHub Webhooks](https://docs.github.com/en/developers/webhooks-and-events/webhooks)
- [AWS SSM Documentation](https://docs.aws.amazon.com/systems-manager/)

---

**Last Updated**: October 31, 2025
