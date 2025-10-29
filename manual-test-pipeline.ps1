# PowerShell script for Windows testing
$ErrorActionPreference = "Stop"

# Configuration
$REGION = "us-east-1"
$BUCKET = "jenkins-pipeline-emmanuel-engineering-com"
$KEY_PREFIX = "myapp/releases"
$REL = (Get-Date -Format "yyyy-MM-ddTHH-mm-ss") + "_manual"
$KEY = "${KEY_PREFIX}/${REL}.zip"
$APP_TAG_KEY = "Role"
$APP_TAG_VAL = "App"

# Navigate to the Vite app directory and ensure dist exists
$VITE_APP_PATH = "my-vite-app"
$DIST_PATH = Join-Path $VITE_APP_PATH "dist"

if (-not (Test-Path $DIST_PATH)) {
    Write-Host "❌ dist folder not found. Building the Vite app first..." -ForegroundColor Red
    Set-Location $VITE_APP_PATH
    npm run build
    Set-Location ..
}

if (-not (Test-Path $DIST_PATH)) {
    Write-Host "❌ dist folder still not found after build. Please check the build process." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Found dist folder at: $DIST_PATH" -ForegroundColor Green

# Create temporary directory for artifact
$TEMP_DIR = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
$ARTIFACT_PATH = Join-Path $TEMP_DIR "artifact.zip"

try {
    Write-Host "📦 Creating artifact from dist folder..." -ForegroundColor Yellow
    
    # Create zip file from dist contents
    Compress-Archive -Path "$DIST_PATH\*" -DestinationPath $ARTIFACT_PATH -Force
    
    Write-Host "☁️ Uploading artifact to S3..." -ForegroundColor Yellow
    
    # Upload to S3
    aws s3 cp $ARTIFACT_PATH "s3://${BUCKET}/${KEY}" --region $REGION
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to upload to S3"
    }
    
    Write-Host "✅ Uploaded to s3://${BUCKET}/${KEY}" -ForegroundColor Green
    
    Write-Host "🚀 Sending SSM command to deploy..." -ForegroundColor Yellow
    
    # Send SSM command
    $CMD_ID = aws ssm send-command `
        --region $REGION `
        --document-name "AWS-RunShellScript" `
        --targets "Key=tag:${APP_TAG_KEY},Values=${APP_TAG_VAL}" `
        --comment "Manual deploy ${REL}" `
        --parameters "commands=sudo /opt/deploy/pull_and_switch.sh ${BUCKET} ${KEY}" `
        --query "Command.CommandId" --output text
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to send SSM command"
    }
    
    Write-Host "📋 Command ID: $CMD_ID" -ForegroundColor Green
    
    # Wait for completion
    Write-Host "⏳ Waiting for deployment to complete..." -ForegroundColor Yellow
    $STATUS = "InProgress"
    $ATTEMPTS = 0
    $MAX_ATTEMPTS = 120
    
    do {
        Start-Sleep -Seconds 5
        $STATUS = aws ssm list-command-invocations --region $REGION `
            --command-id $CMD_ID --details `
            --query "CommandInvocations[0].Status" --output text 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            $STATUS = "InProgress"
        }
        
        Write-Host "📊 SSM status: $STATUS" -ForegroundColor Cyan
        $ATTEMPTS++
        
        if ($ATTEMPTS -gt $MAX_ATTEMPTS) {
            Write-Host "❌ Timeout waiting for deployment" -ForegroundColor Red
            exit 1
        }
    } while ($STATUS -eq "InProgress")
    
    if ($STATUS -eq "Success") {
        Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
        Write-Host "🌐 Your application should now be available via the ALB" -ForegroundColor Green
    } else {
        Write-Host "❌ Deployment failed with status: $STATUS" -ForegroundColor Red
        
        # Get command output for debugging
        Write-Host "📝 Getting command output for debugging..." -ForegroundColor Yellow
        aws ssm list-command-invocations --region $REGION `
            --command-id $CMD_ID --details `
            --query "CommandInvocations[0].CommandPlugins[0].Output" --output text
        exit 1
    }
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    # Cleanup
    if (Test-Path $TEMP_DIR) {
        Remove-Item $TEMP_DIR -Recurse -Force
    }
}