locals {
  # Common tags
  common_tags = {
    ManagedBy   = "Terraform"
    Environment = "dev"
  }

  # Naming prefix
  name_prefix = "alb-https"

  # Availability zones
  azs = data.aws_availability_zones.available.names

  # Web subdomain (e.g., web.example.com)
  web_subdomain = "web.${var.domain_name}"
}
