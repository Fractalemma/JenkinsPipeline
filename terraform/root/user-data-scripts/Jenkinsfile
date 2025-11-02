// Jenkins Pipeline for Vite Application Deployment
// 
// BEFORE USING THIS PIPELINE:
// 1. Update the GitHub repository URL in the 'Checkout' stage (line ~31)
// 2. Update the environment variables below with your AWS configuration (lines ~9-14)
//    - Get values from: terraform output (in terraform/root directory)
//    - See Jenkins-Setup-Guide.md for detailed instructions
//
pipeline {
    agent any
    
    // Automatically adds node and npm to PATH for all stages
    tools {
        nodejs 'NodeJS 22.2.0'
    }
    
    environment {
        REGION = 'us-east-1'                    // TODO: Set your AWS region
        BUCKET = 'YOUR-S3-BUCKET-NAME'          // TODO: Get from: terraform output s3-bucket-name
        KEY_PREFIX = 'myapp/releases'           // S3 prefix for artifacts (customize if needed)
        APP_TAG_KEY = 'Role'                    // TODO: EC2 instance tag key (check your Terraform config)
        APP_TAG_VAL = 'App'                     // TODO: EC2 instance tag value (check your Terraform config)
    }
    
    stages {
        stage('Verify Node.js') {
            steps {
                sh '''
                    echo "Node version: $(node --version)"
                    echo "NPM version: $(npm --version)"
                    echo "Node path: $(which node)"
                    echo "NPM path: $(which npm)"
                '''
            }
        }
        
        stage('Checkout') {
            steps {
                // TODO: Update with your GitHub repository URL
                git branch: 'main',
                    url: 'https://github.com/YOUR_USERNAME/YOUR_REPO.git'
            }
        }
        
        stage('Install Dependencies') {
            steps {
                dir('my-vite-app') {
                    sh 'npm install'
                }
            }
        }
        
        stage('Build') {
            steps {
                dir('my-vite-app') {
                    sh 'npm run build'
                }
            }
        }
        
        stage('Package Artifact') {
            steps {
                script {
                    def timestamp = new Date().format("yyyy-MM-dd'T'HH-mm-ss")
                    env.RELEASE_NAME = "${timestamp}_${env.BUILD_NUMBER}"
                    env.S3_KEY = "${env.KEY_PREFIX}/${env.RELEASE_NAME}.zip"
                    
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
                        aws s3 cp my-vite-app/artifact.zip s3://${env.BUCKET}/${env.S3_KEY} --region ${env.REGION}
                        echo "Uploaded to s3://${env.BUCKET}/${env.S3_KEY}"
                    """
                }
            }
        }
        
        stage('Deploy via SSM') {
            steps {
                script {
                    sh """
                        CMD_ID=\$(aws ssm send-command \\
                            --region ${env.REGION} \\
                            --document-name "AWS-RunShellScript" \\
                            --targets "Key=tag:${env.APP_TAG_KEY},Values=${env.APP_TAG_VAL}" \\
                            --comment "Jenkins deploy ${env.RELEASE_NAME}" \\
                            --parameters commands="sudo /opt/deploy/pull_and_switch.sh ${env.BUCKET} ${env.S3_KEY}" \\
                            --query "Command.CommandId" --output text)
                        
                        echo "SSM Command ID: \$CMD_ID"
                        
                        # Wait for completion
                        STATUS="InProgress"
                        ATTEMPTS=0
                        MAX_ATTEMPTS=120
                        
                        while [ "\$STATUS" = "InProgress" ] && [ \$ATTEMPTS -le \$MAX_ATTEMPTS ]; do
                            sleep 5
                            STATUS=\$(aws ssm list-command-invocations --region ${env.REGION} \\
                                --command-id \$CMD_ID --details \\
                                --query "CommandInvocations[0].Status" --output text 2>/dev/null || echo "InProgress")
                            echo "SSM Status: \$STATUS (attempt \$ATTEMPTS/\$MAX_ATTEMPTS)"
                            ATTEMPTS=\$((ATTEMPTS + 1))
                        done
                        
                        if [ "\$STATUS" != "Success" ]; then
                            echo "Deployment failed with status: \$STATUS"
                            aws ssm list-command-invocations --region ${env.REGION} \\
                                --command-id \$CMD_ID --details \\
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
            echo "Application deployed: ${env.RELEASE_NAME}"
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
