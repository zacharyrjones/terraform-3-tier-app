variable "region" {
  type        = string
  default     = "us-east-2"
  description = "region"
}

variable "environment" {
  type    = string
  default = ""
}

variable "ami_name" {
  type    = string
  default = ""
}

variable "frontend_instance_type" {
  type    = string
  default = ""
}

variable "frontend_instance_count" {
  type    = number
  default = 1
}

variable "backend_instance_type" {
  type    = string
  default = ""
}

variable "backend_instance_count" {
  type    = number
  default = 1
}

variable "domain_name" {
  type = string
  default = ""
}

variable "frontend_alb_idle_timeout" {
  type = number
  default = 60
  description = "timeout for idle connections on the alb"
}

variable "backend_alb_idle_timeout" {
  type = number
  default = 60
  description = "timeout for idle connections on the alb"
}

variable "ssl_security_policy" {
  type = string
  default = ""
}

variable "host_headers" {
  type = list(string)
  default = []
}

variable "waf_ip_whitelist" {
  type = list(string)
  default = []
}

variable "waf_geo_allow" {
  type = list(string)
  default = []
}

variable "waf_host_headers" {
  type = list(string)
  default = []
}