resource "aws_launch_configuration" "backend" {
  name_prefix     = "${var.environment}-backend-"
  image_id        = data.aws_ami.amzn2-latest.id
  instance_type   = var.backend_instance_type
  security_groups = [aws_security_group.main.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "backend" {
  name        = "${var.environment}-backend-sg"
  description = "security group for backend"
  vpc_id      = aws_vpc.main.id
  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "backend_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend.id
}