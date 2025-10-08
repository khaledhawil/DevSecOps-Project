# Jenkins EC2 Instance Module

# Generate SSH key pair using TLS provider
resource "tls_private_key" "jenkins" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally
resource "local_file" "jenkins_private_key" {
  content         = tls_private_key.jenkins.private_key_pem
  filename        = pathexpand("~/.ssh/jenkins-key.pem")
  file_permission = "0600"
}

# Save public key locally
resource "local_file" "jenkins_public_key" {
  content         = tls_private_key.jenkins.public_key_openssh
  filename        = pathexpand("~/.ssh/jenkins-key.pub")
  file_permission = "0644"
}

# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for Jenkins
resource "aws_security_group" "jenkins" {
  name_prefix = "${var.name_prefix}-jenkins-"
  description = "Security group for Jenkins server"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
    description = "SSH access"
  }

  # Jenkins web interface
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_jenkins_cidr_blocks
    description = "Jenkins web interface"
  }

  # HTTPS access (if using reverse proxy)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_jenkins_cidr_blocks
    description = "HTTPS access"
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-jenkins-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# IAM Role for Jenkins EC2
resource "aws_iam_role" "jenkins" {
  name = "${var.name_prefix}-jenkins-role"

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
    var.tags,
    {
      Name = "${var.name_prefix}-jenkins-role"
    }
  )
}

# IAM Policy for Jenkins (access to ECR, S3, EKS, etc.)
resource "aws_iam_role_policy" "jenkins" {
  name = "${var.name_prefix}-jenkins-policy"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:CreateRepository",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.artifacts_bucket}",
          "arn:aws:s3:::${var.artifacts_bucket}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach SSM policy for remote management
resource "aws_iam_role_policy_attachment" "jenkins_ssm" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.name_prefix}-jenkins-profile"
  role = aws_iam_role.jenkins.name

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-jenkins-profile"
    }
  )
}

# SSH Key Pair
resource "aws_key_pair" "jenkins" {
  key_name   = "${var.name_prefix}-jenkins-key"
  public_key = tls_private_key.jenkins.public_key_openssh

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-jenkins-key"
    }
  )
}

# Elastic IP for Jenkins
resource "aws_eip" "jenkins" {
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-jenkins-eip"
    }
  )
}

# Jenkins EC2 Instance
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  iam_instance_profile   = aws_iam_instance_profile.jenkins.name
  key_name               = aws_key_pair.jenkins.key_name

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = merge(
      var.tags,
      {
        Name = "${var.name_prefix}-jenkins-root-volume"
      }
    )
  }

  # Additional volume for Jenkins data
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = var.jenkins_data_volume_size
    volume_type           = "gp3"
    delete_on_termination = false
    encrypted             = true

    tags = merge(
      var.tags,
      {
        Name = "${var.name_prefix}-jenkins-data-volume"
      }
    )
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              yum update -y
              
              # Install required packages
              yum install -y python3 python3-pip wget git
              
              # Format and mount Jenkins data volume
              if ! grep -q '/var/lib/jenkins' /etc/fstab; then
                mkfs -t xfs /dev/nvme1n1
                mkdir -p /var/lib/jenkins
                echo '/dev/nvme1n1 /var/lib/jenkins xfs defaults,nofail 0 2' >> /etc/fstab
                mount -a
              fi
              
              # Set hostname
              hostnamectl set-hostname ${var.name_prefix}-jenkins
              
              # Create ansible ready flag
              echo "ready" > /tmp/ansible-ready
              EOF

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-jenkins"
      Environment = var.environment
      Role        = "jenkins"
      AnsibleManaged = "true"
    }
  )

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# Associate Elastic IP with Jenkins instance
resource "aws_eip_association" "jenkins" {
  instance_id   = aws_instance.jenkins.id
  allocation_id = aws_eip.jenkins.id
}

# CloudWatch Log Group for Jenkins
resource "aws_cloudwatch_log_group" "jenkins" {
  name              = "/aws/ec2/jenkins/${var.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-jenkins-logs"
    }
  )
}

# SNS Topic for Jenkins alerts
resource "aws_sns_topic" "jenkins_alerts" {
  name = "${var.name_prefix}-jenkins-alerts"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-jenkins-alerts"
    }
  )
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "jenkins_cpu" {
  alarm_name          = "${var.name_prefix}-jenkins-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors Jenkins EC2 CPU utilization"
  alarm_actions       = [aws_sns_topic.jenkins_alerts.arn]

  dimensions = {
    InstanceId = aws_instance.jenkins.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "jenkins_status_check" {
  alarm_name          = "${var.name_prefix}-jenkins-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "This metric monitors Jenkins EC2 status checks"
  alarm_actions       = [aws_sns_topic.jenkins_alerts.arn]

  dimensions = {
    InstanceId = aws_instance.jenkins.id
  }

  tags = var.tags
}
