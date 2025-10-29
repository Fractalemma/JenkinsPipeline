# Auto Scaling Group Module Updates

## Changes Made for SSM Integration

The ASG module has been updated to support SSM command targeting by properly tagging instances created by the Auto Scaling Group.

### New Variables Added

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| instance_role_tag_key | Tag key to identify the role of instances created by this ASG | `string` | `"Role"` | no |
| instance_role_tag_value | Tag value to identify the role of instances created by this ASG | `string` | `"App"` | no |
| environment | Environment name (e.g., dev, staging, prod) | `string` | `"dev"` | no |

### Tags Applied to EC2 Instances

The ASG now automatically applies the following tags to all instances it creates:

1. **Name**: `${module_prefix}-asg-instance`
2. **Role**: Configurable via `instance_role_tag_key`/`instance_role_tag_value` (default: `Role=App`)
3. **Environment**: Configurable via `environment` variable
4. **ManagedBy**: `ASG`

### Usage with IAM Instance Profiles

When using with the IAM instance profile module, ensure the tag values match:

```hcl
# IAM Instance Profile Module
module "iam_instance_profiles" {
  source = "./modules/iam-instance-profile"
  
  module_prefix     = "my-project"
  s3_bucket_arn     = module.s3.bucket_arn
  app_ec2_tag_key   = "Role"
  app_ec2_tag_value = "App"
}

# ASG Module for App instances
module "app_asg" {
  source = "./modules/asg"
  
  # ... other variables ...
  instance_role_tag_key   = "Role"        # Must match IAM module
  instance_role_tag_value = "App"         # Must match IAM module
  environment            = "production"
  iam_instance_profile    = module.iam_instance_profiles.app_ec2_instance_profile_arn
}
```

This ensures that Jenkins can target the App EC2 instances with SSM commands using the tag-based filtering.
