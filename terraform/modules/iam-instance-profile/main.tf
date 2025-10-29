# ==============================================
# JENKINS EC2 ROLE
# ==============================================

# IAM Role for Jenkins EC2 instances
resource "aws_iam_role" "jenkins_ec2_role" {
  name = "${var.module_prefix}-jenkins-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.module_prefix}-jenkins-ec2-role"
    Type = "Jenkins"
  }
}

# Attach AWS managed policy for SSM (for debug access)
resource "aws_iam_role_policy_attachment" "jenkins_ssm_managed_policy" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Custom policy for Jenkins EC2 to send SSM commands and access S3
resource "aws_iam_policy" "jenkins_ec2_policy" {
  name        = "${var.module_prefix}-jenkins-ec2-policy"
  description = "Policy for Jenkins EC2 to send SSM commands and access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ---- Allow SendCommand on SSM documents (no restriction needed)
      # SSM Documents are pre-defined scripts/commands that define WHAT to execute
      # Examples: AWS-RunShellScript, AWS-UpdateSSMAgent, AWS-ConfigureAWSPackage
      # These are AWS-managed templates that contain the actual commands to run
      # Permission on documents is needed to "use" the script template
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:CancelCommand"
        ]
        Resource = [
          "arn:aws:ssm:*::document/AWS-*",        # AWS-managed documents (like AWS-RunShellScript)
          "arn:aws:ssm:*:*:document/*"            # Custom documents (if any)
        ]
      },

      # ---- Restrict SendCommand to tagged instances only
      # EC2 instances are the targets WHERE the document/script will be executed
      # This permission controls which specific EC2 instances can receive commands
      # We restrict this to only instances tagged with Role=App for security
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand"
        ]
        Resource = "arn:aws:ec2:*:*:instance/*"   # Target EC2 instances
        Condition = {
          StringEquals = {
            "ssm:resourceTag/${var.app_ec2_tag_key}" = var.app_ec2_tag_value
          }
        }
      },

      # ---- Read-only SSM queries (no restriction, needed for Jenkins CLI to query status)
      {
        Effect = "Allow"
        Action = [
          "ssm:ListCommandInvocations",
          "ssm:ListCommands",
          "ssm:GetCommandInvocation",
          "ssm:DescribeInstanceInformation"
        ]
        Resource = "*"
      },

      # ---- S3 read/write for artifacts
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.module_prefix}-jenkins-ec2-policy"
  }
}

# Attach custom policy to Jenkins role
resource "aws_iam_role_policy_attachment" "jenkins_custom_policy" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = aws_iam_policy.jenkins_ec2_policy.arn
}

# Instance Profile for Jenkins EC2 instances
resource "aws_iam_instance_profile" "jenkins_ec2_profile" {
  name = "${var.module_prefix}-jenkins-ec2-profile"
  role = aws_iam_role.jenkins_ec2_role.name

  tags = {
    Name = "${var.module_prefix}-jenkins-ec2-profile"
    Type = "Jenkins"
  }
}

# ==============================================
# APP EC2 ROLE
# ==============================================

# IAM Role for App EC2 instances
resource "aws_iam_role" "app_ec2_role" {
  name = "${var.module_prefix}-app-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.module_prefix}-app-ec2-role"
    Type = "App"
  }
}

# Attach AWS managed policy for SSM (for debug access and receiving commands)
resource "aws_iam_role_policy_attachment" "app_ssm_managed_policy" {
  role       = aws_iam_role.app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Custom policy for App EC2 to pull artifacts from S3
resource "aws_iam_policy" "app_ec2_policy" {
  name        = "${var.module_prefix}-app-ec2-policy"
  description = "Policy for App EC2 to pull artifacts from S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.module_prefix}-app-ec2-policy"
  }
}

# Attach custom policy to App role
resource "aws_iam_role_policy_attachment" "app_custom_policy" {
  role       = aws_iam_role.app_ec2_role.name
  policy_arn = aws_iam_policy.app_ec2_policy.arn
}

# Instance Profile for App EC2 instances
resource "aws_iam_instance_profile" "app_ec2_profile" {
  name = "${var.module_prefix}-app-ec2-profile"
  role = aws_iam_role.app_ec2_role.name

  tags = {
    Name = "${var.module_prefix}-app-ec2-profile"
    Type = "App"
  }
}
