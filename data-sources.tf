data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid    = "ec2 assume role policy"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

data "aws_iam_policy_document" "base_role" {
  statement {
    effect = "Allow"

    actions = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:GetManifest",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation"
    ]

    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]

    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply"
    ]

    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:CreateLogGroup"
    ]

    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameter"
    ]

    resources = [
      "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
    ]
  }
}

data "aws_ami" "amzn2-latest" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_name]
  }
}

data "template_file" "frontend_user_data" {
  template = "${file("templates/frontend_user_data.tpl")}"
}

data "template_file" "backend_user_data" {
  template = "${file("templates/backend_user_data.tpl")}"
}

data "aws_iam_policy_document" "access_logs_bucket_policy" {
  statement {
    sid = "lb access logs s3 policy"
    effect = "Allow"

    principals {
      identifiers = ["arn:aws:iam::${data.aws_elb_service_account.main.id}:root"]
      type = "AWS"
    }

    actions = ["s3:PutObject"]

    resources = ["arn:aws:s3:::${var.environment}-access-logs/*"]
  }
}