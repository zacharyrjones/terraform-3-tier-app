resource "aws_security_group" "frontend_alb" {
  name        = "${var.environment}-frontend-alb-sg"
  description = "security group for frontend alb"
  vpc_id      = aws_vpc.main.id
  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_alb.id
}

resource "aws_security_group_rule" "https_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_alb.id
}

resource "aws_security_group_rule" "fronent_alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_alb.id
}

resource "aws_lb" "frontend" {
  name = "${var.environment}-frontend-lb"
  internal = false
  load_balancer_type = "application"
  subnets = [aws_subnet.public-1-a.id, aws_subnet.public-1-b.id]
  security_groups = [aws_security_group.frontend_alb.id]
  ip_address_type = "ipv4"
  enable_http2 = true
  enable_deletion_protection = true
  idle_timeout = var.frontend_alb_idle_timeout

  access_logs {
    bucket = aws_s3_bucket.access_logs.bucket
    prefix = "alb/${var.environment}-frontend-lb"
    enabled = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.frontend.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Forbbiden"
      status_code = "403"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.frontend.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = var.ssl_security_policy
  certificate_arn = aws_acm_certificate.wildcard.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Forbbiden"
      status_code = "403"
    }
  }
}

resource "aws_lb_listener_rule" "http_host_header" {
  listener_arn = aws_lb_listener.http.arn
  priority = 1

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    host_header {
      values = var.host_headers
    }
  }
}

resource "aws_lb_listener_rule" "https_host_header" {
  listener_arn = aws_lb_listener.https.arn
  priority = 1

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    host_header {
      values = var.host_headers
    }
  }
}

resource "aws_lb_listener_certificate" "wildcard" {
  listener_arn = aws_lb_listener.https.arn
  certificate_arn = aws_acm_certificate.wildcard.arn
}

resource "aws_lb_target_group" "frontend" {
  name = "${var.environment}-frontend-target-group"
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

resource "aws_autoscaling_group" "frontend" {
  name = "${var.environment}-frontend-asg"
  min_size = 2
  max_size = 2
  desired_capacity = 2
  health_check_type = "ELB"
  health_check_grace_period = 60
  launch_configuration = aws_launch_configuration.frontend.id
  vpc_zone_identifier = [aws_subnet.public-1-a.id, aws_subnet.public-1-b.id]
  target_group_arns = [aws_lb_target_group.frontend.arn]
}

resource "aws_autoscaling_policy" "frontend_up" {
  name = "${var.environment}-frontend-up"
  scaling_adjustment = 1
  adjustment_type = "Change In Capacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.frontend.name
}

resource "aws_autoscaling_policy" "frontend_down" {
  name = "${var.environment}-frontend-down"
  scaling_adjustment = -1
  adjustment_type = "Change In Capacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.frontend.name
}

resource "aws_cloudwatch_metric_alarm" "frontend_cpu_alarm_up" {
  alarm_name = "frontend-cpu-alarm-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "60"

  dimensions = {
    AutoScaling_Group_Name = aws_autoscaling_group.frontend.name
  }

  alarm_description = "metric to moniter utalization"
  alarm_actions = [aws_autoscaling_policy.frontend_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "frontend_cpu_alarm_down" {
  alarm_name = "frontend-cpu-alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  dimensions = {
    AutoScaling_Group_Name = aws_autoscaling_group.frontend.name
  }

  alarm_description = "metric to moniter utalization"
  alarm_actions = [aws_autoscaling_policy.frontend_down.arn]
}

resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.frontend.arn
  web_acl_arn = aws_wafv2_web_acl.main.arn
}