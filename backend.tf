# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# User data script to install and configure nginx
locals {
  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nginx
    systemctl start nginx
    systemctl enable nginx

    # Ensure SSM agent is running (pre-installed on Amazon Linux 2023)
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    # Create a simple HTML page
    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
    <head>
        <title>HTTPS ALB Demo</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                max-width: 800px;
                margin: 50px auto;
                padding: 20px;
                background-color: #f5f5f5;
            }
            .container {
                background-color: white;
                padding: 30px;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            h1 { color: #2c3e50; }
            .info { color: #7f8c8d; }
            .success { color: #27ae60; font-weight: bold; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>HTTPS ALB Demo</h1>
            <p class="success">Successfully connected via HTTPS!</p>
            <p class="info">This page is served from an EC2 instance behind an Application Load Balancer with an ACM certificate.</p>
            <p class="info">HTTP requests are automatically redirected to HTTPS.</p>
        </div>
    </body>
    </html>
    HTML
  EOF
}

# EC2 instance in private subnet
resource "aws_instance" "backend" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.private[0].id
  iam_instance_profile = aws_iam_instance_profile.backend.name

  vpc_security_group_ids = [aws_security_group.backend.id]
  user_data              = local.user_data

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${local.name_prefix}-backend"
    }
  )
}
