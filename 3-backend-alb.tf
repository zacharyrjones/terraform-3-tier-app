resource "aws_security_group" "backend_alb" {
  name        = "${var.environment}-backend-alb-sg"
  description = "security group for backend alb"
  vpc_id      = aws_vpc.main.id
  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "backend_alb_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend_alb.id
}

resource "aws_security_group_rule" "backend_alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend_alb.id
}

resource "aws_lb" "backend" {
  name = "${var.environment}-backend-lb"
  internal = false
  load_balancer_type = "application"
  subnets = [aws_subnet.public-1-a.id, aws_subnet.public-1-b.id]
  security_groups = [aws_security_group.backend_alb.id]
  ip_address_type = "ipv4"
  enable_http2 = true
  enable_deletion_protection = true
  idle_timeout = var.backend_alb_idle_timeout

  access_logs {
    bucket = aws_s3_bucket.access_logs.bucket
    prefix = "alb/${var.environment}-backend-lb"
    enabled = true
  }
}

resource "aws_lb_listener" "backend_alb_http" {
  load_balancer_arn = aws_lb.backend.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.backend.arn

    fixed_response {
      content_type = "text/plain"
      message_body = "Forbbiden"
      status_code = "403"
    }
  }
}

resource "aws_lb_target_group" "backend" {
  name = "${var.environment}-backend-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id

  health_check {
    interval = 30
    path = "/"
    port = 80
    protocol = "HTTP"
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 3
    matcher = "200-299"
  }

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Environment = var.environment
  }
}

resource "aws_autoscaling_group" "backend" {
  name = "${var.environment}-backend-asg"
  min_size = 2
  max_size = 2
  desired_capacity = 2
  health_check_type = "ELB"
  health_check_grace_period = 60
  launch_configuration = aws_launch_configuration.backend.id
  vpc_zone_identifier = [aws_subnet.public-1-a.id, aws_subnet.public-1-b.id]
  target_group_arns = [aws_lb_target_group.backend.arn]
}

resource "aws_autoscaling_policy" "backend_alb_up" {
  name = "${var.environment}-backend-up"
  scaling_adjustment = 1
  adjustment_type = "Change In Capacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.backend.name
}

resource "aws_autoscaling_policy" "backend_alb_down" {
  name = "${var.environment}-backend-down"
  scaling_adjustment = -1
  adjustment_type = "Change In Capacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.backend.name
}

resource "aws_cloudwatch_metric_alarm" "backend_alb_cpu_alarm_up" {
  alarm_name = "backend-cpu-alarm-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "60"

  dimensions = {
    AutoScaling_Group_Name = aws_autoscaling_group.backend.name
  }

  alarm_description = "metric to moniter utalization"
  alarm_actions = [aws_autoscaling_policy.backend_alb_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "backend_alb_cpu_alarm_down" {
  alarm_name = "backend-cpu-alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  dimensions = {
    AutoScaling_Group_Name = aws_autoscaling_group.backend.name
  }

  alarm_description = "metric to moniter utalization"
  alarm_actions = [aws_autoscaling_policy.backend_alb_down.arn]
}