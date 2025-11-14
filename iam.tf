# IAM role for EC2 instance to enable SSM
resource "aws_iam_role" "backend" {
  name = "${local.name_prefix}-backend-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${local.name_prefix}-backend-role"
    }
  )
}

# Attach AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "backend_ssm" {
  role       = aws_iam_role.backend.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "backend" {
  name = "${local.name_prefix}-backend-profile"
  role = aws_iam_role.backend.name

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${local.name_prefix}-backend-profile"
    }
  )
}
