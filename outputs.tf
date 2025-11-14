output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.main.arn
}

output "https_url" {
  description = "Full HTTPS URL for the web subdomain"
  value       = "https://${local.web_subdomain}"
}

output "http_url" {
  description = "HTTP URL for the web subdomain (will redirect to HTTPS)"
  value       = "http://${local.web_subdomain}"
}

output "backend_instance_id" {
  description = "EC2 instance ID for the backend"
  value       = aws_instance.backend.id
}

output "ssm_connect_command" {
  description = "Command to connect to the backend instance via SSM Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.backend.id}"
}
