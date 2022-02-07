provider "aws" {
  region = var.region
}

////////////////////////
// MAIN SECURITY GROUP
////////////////////////
resource "aws_security_group" "main" {
  name        = "${var.environment}-ec2-main"
  description = "main ec2 security group"
  vpc_id      = aws_vpc.main.id
}
resource "aws_security_group_rule" "allow_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

////////////////////////
// MAIN EC2 ROLE
////////////////////////
resource "aws_iam_role" "main" {
  name               = "${var.environment}-ec2-main"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_policy" "main" {
  name   = "${var.environment}-ec2-main-policy"
  policy = data.aws_iam_policy_document.base_role.json
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}

////////////////////////
// ROUTE53
////////////////////////
resource "aws_route53_zone" "main" {
  name = var.domain_name
}

////////////////////////
// CERTIFICATES
////////////////////////
resource "aws_acm_certificate" "wildcard" {
  domain_name = "*.${var.domain_name}"
  validation_method = "DNS"

  tags = {
    Name = "wildcard_certificate"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "wildcard" {
  zone_id = aws_route53_zone.main.id
  ttl =     60
  name =    tolist(aws_acm_certificate.wildcard.domain_validation_options)[0].resource_record_name
  type =    tolist(aws_acm_certificate.wildcard.domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.wildcard.domain_validation_options)[0].resource_record_value]
}

resource "aws_acm_certificate_validation" "wildcard" {
  certificate_arn = aws_acm_certificate.wildcard.arn
  validation_record_fqdns = [aws_route53_record.wildcard.fqdn]
}

////////////////////////
// ACCESS LOGS S3 BUCKET
////////////////////////
resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.environment}-access-logs"
  acl = "private"
  policy = data.aws_iam_policy_document.access_logs_bucket_policy.json

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Environment = "var.environment"
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.bucket
  block_public_acls = true
  ignore_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
}