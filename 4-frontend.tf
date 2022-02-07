resource "aws_launch_configuration" "frontend" {
  name_prefix     = "${var.environment}-frontend-"
  image_id        = data.aws_ami.amzn2-latest.id
  instance_type   = var.frontend_instance_type
  security_groups = [aws_security_group.main.id]

  user_data = "${base64encode(data.template_file.frontend_user_data.rendered)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "frontend" {
  name        = "${var.environment}-frontend-sg"
  description = "security group for frontend"
  vpc_id      = aws_vpc.main.id
  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "frontend_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
}

