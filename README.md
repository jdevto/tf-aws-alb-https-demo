# HTTPS ALB Terraform Demo

A minimal, reusable Terraform configuration demonstrating how to deploy an HTTPS-enabled Application Load Balancer using an ACM public certificate with automatic HTTP→HTTPS redirect.

## Overview

This Terraform configuration creates a complete AWS infrastructure stack that includes:

- **VPC** with public and private subnets across multiple availability zones
- **Application Load Balancer** with HTTP (port 80) and HTTPS (port 443) listeners
- **ACM Certificate** with DNS validation via Route53
- **EC2 Backend** running nginx serving a simple HTML page
- **Security Groups** configured for secure communication
- **NAT Gateway** for EC2 outbound internet access (single AZ for cost optimization)

### Architecture

```plaintext
Internet
   │
   ▼
[ALB] (Public Subnets)
   │ HTTPS (443) / HTTP (80 → 301 redirect)
   ▼
[Target Group]
   │
   ▼
[EC2 Instance] (Private Subnet)
   │
   ▼
[Nginx] serving HTML
```

## Prerequisites

- AWS account with appropriate permissions
- Terraform >= 1.0 installed
- AWS CLI configured with credentials
- Route53 hosted zone for your domain
- Domain name registered and managed in Route53

### Required IAM Permissions

The AWS credentials must have permissions to create and manage:

- VPC, Subnets, Internet Gateway, NAT Gateway, Route Tables
- Application Load Balancer, Target Groups, Listeners
- EC2 Instances, Security Groups
- ACM Certificates
- Route53 Records

## Input Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `domain_name` | Root domain name (e.g., "example.com"). A subdomain `web.example.com` will be created automatically. Route53 hosted zone will be looked up automatically. | `string` | - | yes |
| `vpc_cidr` | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| `instance_type` | EC2 instance type for the backend | `string` | `"t3.micro"` | no |
| `tags` | Additional tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Output | Description |
|--------|-------------|
| `alb_dns_name` | DNS name of the Application Load Balancer |
| `certificate_arn` | ARN of the ACM certificate |
| `https_url` | Full HTTPS URL for the web subdomain (e.g., <https://web.example.com>) |
| `http_url` | HTTP URL for the web subdomain (will redirect to HTTPS) |
| `backend_instance_id` | EC2 instance ID for the backend |
| `ssm_connect_command` | Command to connect to the backend instance via SSM Session Manager |

## Usage

### 1. Clone or navigate to this directory

```bash
cd tf-aws-alb-https-demo
```

### 2. Create a `terraform.tfvars` file

```hcl
domain_name    = "example.com"
instance_type  = "t3.micro"
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the execution plan

```bash
terraform plan
```

### 5. Apply the configuration

```bash
terraform apply
```

This will:

1. Create the VPC and networking components
2. Create Route53 A record for `web.example.com` pointing to the ALB
3. Request an ACM certificate for `web.example.com`
4. Create DNS validation records in Route53
5. Wait for certificate validation (may take a few minutes)
6. Create the ALB, target group, and listeners
7. Launch the EC2 instance with nginx
8. Configure security groups

**Note**: The Route53 record for `web.example.com` is created automatically. No manual DNS setup is required.

### 6. Wait for DNS propagation

DNS changes may take a few minutes to propagate. You can check with:

```bash
dig web.example.com
# or
nslookup web.example.com
```

## Testing

### Test HTTP to HTTPS Redirect

```bash
curl -I http://web.example.com
```

You should see a `301 Moved Permanently` response with a `Location` header pointing to the HTTPS URL.

### Test HTTPS Connection

```bash
curl https://web.example.com
```

You should see the HTML content of the demo page.

### Test in Browser

1. Navigate to `http://web.example.com` - should automatically redirect to HTTPS
2. Navigate to `https://web.example.com` - should display the demo page
3. Check the browser's security indicator to verify the certificate is valid

### Verify Certificate

```bash
openssl s_client -connect web.example.com:443 -servername web.example.com
```

Look for the certificate details and verify it's issued by Amazon.

## Accessing the Backend Instance

The EC2 instance is configured with AWS Systems Manager (SSM) Session Manager for secure access without SSH keys or public IP addresses.

### SSM Prerequisites

- AWS CLI installed and configured
- Session Manager plugin installed (see [AWS documentation](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html))

### Connect via SSM

After deployment, use the `ssm_connect_command` output to connect:

```bash
aws ssm start-session --target <instance-id>
```

Or use the output directly:

```bash
terraform output -raw ssm_connect_command | bash
```

Once connected, you can check nginx status:

```bash
sudo systemctl status nginx
sudo tail -f /var/log/nginx/access.log
```

## Troubleshooting

### Certificate Validation Failing

- Ensure the Route53 hosted zone exists and is accessible
- Check that DNS validation records were created correctly
- Verify the domain name matches the hosted zone
- Wait a few minutes for DNS propagation

### ALB Health Check Failing

- Check EC2 instance status in the AWS Console
- Verify security group allows traffic from ALB
- Connect to the instance via SSM Session Manager and check nginx status:

  ```bash
  aws ssm start-session --target <instance-id>
  sudo systemctl status nginx
  ```

### 502 Bad Gateway

- Ensure the target group health checks are passing
- Verify the EC2 instance is running and nginx is active
- Check security group rules

### DNS Not Resolving

- Verify the Route53 A record for `web.example.com` exists and points to the ALB
- Wait for DNS propagation (can take up to 48 hours, usually much faster)
- Check that the ALB DNS name is correct
- Verify you're accessing `web.example.com`, not the root domain

## Cleanup

To destroy all created resources:

```bash
terraform destroy
```

**Note**: This will delete all resources including the VPC, ALB, EC2 instance, and ACM certificate. Make sure you want to delete everything before proceeding.

## Cost Considerations

This configuration creates the following billable resources:

- NAT Gateway (~$0.045/hour + data transfer)
- Application Load Balancer (~$0.0225/hour + LCU usage)
- EC2 instance (varies by instance type, t3.micro is free tier eligible)
- Data transfer costs

To minimize costs:

- Use `t3.micro` instance type (free tier eligible for new AWS accounts)
- Destroy the infrastructure when not in use
- Consider using a single NAT Gateway (as configured) instead of one per AZ

## Security Notes

- The ALB security group allows traffic from `0.0.0.0/0` on ports 80 and 443
- The backend EC2 security group only allows traffic from the ALB security group
- EC2 instances are in private subnets and not directly accessible from the internet
- HTTPS uses TLS 1.3 security policy

## License

See LICENSE file for details.
