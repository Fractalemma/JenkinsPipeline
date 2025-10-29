# Notes:
# - 3 Security Groups for:
#   - Application Load Balancer (ALB)
#   - Web Tier
#   - Jenkins Server (CD/CI Tier)

resource "aws_security_group" "alb_sg" {
  name        = "${var.module_prefix}-alb-sg"
  description = "Enable http/https access on port 80/443"
  vpc_id      = var.vpc_id

  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Ready for SSL/TLS certificate future use:
  ingress {
    description = "https access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  // In Terraform we need to define egress rules explicitly
  egress {
    description = "all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb_sg"
  }
}

# create security group for the Web Tier
resource "aws_security_group" "web_sg" {
  name        = "${var.module_prefix}-web-sg"
  description = "Enable http/https access on port 80 for elb sg"
  vpc_id      = var.vpc_id

  ingress {
    description     = "http access"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web_sg"
  }
}

# create security group for the Jenkins Pipeline Agents
resource "aws_security_group" "pipeline_agent_sg" {
  name        = "${var.module_prefix}-pipeline-agent-sg"
  description = "Enable access for Jenkins pipeline agents"
  vpc_id      = var.vpc_id

  ingress {
    description = "http access for Jenkins Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.jenkins_allowed_http_cidrs
  }

  egress {
    description = "all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pipeline_agent_sg"
  }
}

# See:
# - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
