resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.sg_id]
  associate_public_ip_address = var.enable_public_ip
  user_data_base64            = var.user_data
  iam_instance_profile        = var.iam_instance_profile
  tags = {
    Name = "${var.module_prefix}-instance"
  }
}
