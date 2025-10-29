# IAM Instance Profile Module

This module creates IAM roles and instance profiles for both Jenkins and App EC2 instances with specific permissions for a CI/CD pipeline.

## Resources Created

### Jenkins EC2 Role

- **Purpose**: For Jenkins agents/servers
- **Permissions**:
  - SSM access for debugging (can be accessed via Session Manager)
  - Send SSM Run Commands to App EC2 instances (filtered by tags)
  - Full S3 access to the artifacts bucket (upload/download artifacts)

### App EC2 Role

- **Purpose**: For application servers
- **Permissions**:
  - SSM access for debugging and receiving commands from Jenkins
  - Read-only S3 access to pull artifacts from the bucket

## Usage

```hcl
module "iam_instance_profiles" {
  source = "./modules/iam-instance-profile"
  
  module_prefix     = "my-project"
  s3_bucket_arn     = module.s3.bucket_arn
  app_ec2_tag_key   = "Role"        # Optional, defaults to "Role"
  app_ec2_tag_value = "App"         # Optional, defaults to "App"
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| module_prefix | Prefix for resource names | `string` | n/a | yes |
| s3_bucket_arn | ARN of the S3 bucket for artifacts | `string` | n/a | yes |
| app_ec2_tag_key | Tag key to identify App EC2 instances for SSM commands | `string` | `"Role"` | no |
| app_ec2_tag_value | Tag value to identify App EC2 instances for SSM commands | `string` | `"App"` | no |

## Outputs

| Name | Description |
|------|-------------|
| jenkins_ec2_instance_profile_name | Name of the Jenkins EC2 instance profile |
| jenkins_ec2_instance_profile_arn | ARN of the Jenkins EC2 instance profile |
| jenkins_ec2_role_arn | ARN of the Jenkins EC2 IAM role |
| jenkins_ec2_role_name | Name of the Jenkins EC2 IAM role |
| app_ec2_instance_profile_name | Name of the App EC2 instance profile |
| app_ec2_instance_profile_arn | ARN of the App EC2 instance profile |
| app_ec2_role_arn | ARN of the App EC2 IAM role |
| app_ec2_role_name | Name of the App EC2 IAM role |

## Important Notes

1. **App EC2 Tagging**: Make sure your App EC2 instances are tagged with the specified key/value pair (default: `Role=App`) so Jenkins can target them with SSM commands.

   **For Auto Scaling Groups**: The ASG module has been updated to automatically propagate the role tags to all instances it creates. When using the ASG module, set the `instance_role_tag_key` and `instance_role_tag_value` variables to match the values used in your IAM instance profile module.

   Example ASG module usage:

   ```hcl
   module "app_asg" {
     source = "./modules/asg"
     
     # ... other variables ...
     instance_role_tag_key   = "Role"
     instance_role_tag_value = "App"
     iam_instance_profile    = module.iam_instance_profiles.app_ec2_instance_profile_arn
   }
   ```

2. **S3 Permissions**
   - Jenkins has full access (read/write/delete) to the S3 bucket
   - App instances have read-only access to pull artifacts

3. **SSM Command Targeting**: Jenkins can only send SSM commands to EC2 instances that have the correct tags. This provides security isolation and works seamlessly with Auto Scaling Groups as the tags are automatically applied to new instances.

## Security Considerations

- The Jenkins role is more privileged and should only be attached to trusted Jenkins instances
- App instances have minimal permissions (SSM + S3 read-only)
- SSM commands are restricted by resource tags to prevent unauthorized access
- All roles follow the principle of least privilege
