resource "aws_wafv2_ip_set" "whitelist" {
  name = "${var.environment}-ip-whitelist"
  description = "waf ip whitelist"
  scope ="REGIONAL"
  ip_address_version = "IPV4"
  addresses = var.waf_ip_whitelist

  tags = {
    Environment = var.environment
  }
}

resource "aws_wafv2_web_acl" "main" {
  name = "${var.environment}-main-acl"
  description = ""
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name = "ip-whitelist"
    priority = 1
   
    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.whitelist.arn
      }
    }
  }

  rule {
    name = "geo-match"
    priority = 10
   
    action {
      block {}
    }

    statement {
      geo_match_statement {
        country_codes = var.waf_geo_allow
      }
    }
  }
}