# Jenkins CI/CD Pipeline for Vite App

Automated deployment pipeline that builds a Vite application and deploys it to AWS App EC2 instances via S3 and SSM.

![Pipeline Architecture](docs/jenkins-pipeline-diagram.svg)

## Quick Start

1. **Deploy Infrastructure** - Use Terraform to provision AWS resources (VPC, ALB, ASG, S3, IAM roles)
2. **Setup Jenkins** - Follow [Jenkins Setup Guide](docs/Jenkins-Setup-Guide.md) to configure Jenkins and create the pipeline job
3. **Configure Webhook** - Set up GitHub webhook to trigger builds automatically
4. **Deploy** - Push to main branch or trigger manually

## Architecture

- **Jenkins EC2**: Builds app, uploads artifacts to S3, sends SSM commands to App instances
- **App EC2 (ASG)**: Receives SSM commands, pulls artifacts from S3, deploys to Nginx
- **ALB**: Routes traffic to App instances
- **S3**: Stores build artifacts
- **IAM Roles**: Jenkins (full S3 + SSM send), App (S3 read + SSM receive)

## Pipeline Stages

1. **Checkout** - Clone repository
2. **Install** - Install npm dependencies
3. **Build** - Build Vite app (`npm run build`)
4. **Package** - Zip build artifacts with timestamp
5. **Upload** - Upload to S3
6. **Deploy** - Send SSM command to App instances to pull and deploy
7. **Wait** - Monitor deployment status

## Key Features

- Tag-based SSM targeting (Role=App)
- Automatic ASG instance tagging
- Timestamped artifact versioning
- Deployment status monitoring
- Zero-downtime deployments

## Documentation

- [Jenkins Setup Guide](docs/Jenkins-Setup-Guide.md) - Complete Jenkins configuration and pipeline setup
- [IAM Instance Profiles](docs/IAM-Instance-Profiles.md) - IAM roles and permissions for Jenkins and App instances
- [ASG-SSM Integration](docs/ASG-SSM-Integration.md) - Auto Scaling Group configuration for SSM targeting
- [Initial Tests](docs/Initial-Tests.md) - Manual testing procedures for permissions and deployment

## Requirements

- AWS Account with appropriate permissions
- Terraform >= 1.0
- Jenkins with NodeJS plugin
- Node.js 22.2.0+ (managed by Jenkins)
- GitHub repository (public or private with credentials)

## Configuration

Update `Jenkinsfile` environment variables:

- `REGION` - AWS region
- `BUCKET` - S3 bucket name
- `KEY_PREFIX` - S3 path prefix
- `APP_TAG_KEY/APP_TAG_VAL` - SSM target tags

Ensure ASG and IAM modules use matching tags for SSM targeting.
