resource "aws_launch_template" "launch_tpl" {
  name          = "${var.module_prefix}-tpl"
  image_id      = var.ami_id
  instance_type = var.instance_type
  user_data     = var.user_data

  iam_instance_profile {
    arn = var.iam_instance_profile
  }

  vpc_security_group_ids = [var.sg_id]
  tags = {
    Name = "${var.module_prefix}-launch-tpl"
  }
}

# See:
# - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template



resource "aws_autoscaling_group" "this" {
  name                      = "${var.module_prefix}-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_cap
  health_check_grace_period = var.asg_health_check_grace_period
  health_check_type         = var.asg_health_check_type
  vpc_zone_identifier       = [var.sub_a_id, var.sub_b_id]
  target_group_arns         = [var.tg_arn]

  launch_template {
    id      = aws_launch_template.launch_tpl.id
    version = aws_launch_template.launch_tpl.latest_version
  }

  # Tags that will be propagated to EC2 instances
  tag {
    key                 = "Name"
    value               = "${var.module_prefix}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = var.instance_role_tag_key
    value               = var.instance_role_tag_value
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "ASG"
    propagate_at_launch = true
  }
}

# See:
# - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
