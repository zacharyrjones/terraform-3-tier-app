region = "us-east-2"
environment = "staging"
ami_name = "amzn2-ami-hvm-*-x86_64-ebs"
frontend_instance_type = "t3.nano"
frontend_instance_count = 2
backend_instance_type = "t3.micro"
backend_instance_count = 2
domain_name = "domainnametest.com"
host_headers = ["test.domainnametest.com"]
frontend_alb_idle_timeout = 120
backend_alb_idle_timeout = 120
ssl_security_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"