provider "aws" {
  region = "us-east-1"
}
############################################
# IAM Role for EC2 (ECR + SSM Access)
############################################
resource "aws_iam_role" "ec2_role" {
  name = "cloth-blog-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "ec2.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "cloth-blog-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

############################################
# Security Group
############################################
resource "aws_security_group" "cloth_blog_sg" {
  name        = "cloth-blog-sg"
  description = "Allow HTTP (80) and SSH (22)"

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloth-blog-sg"
  }
}

############################################
# Latest Amazon Linux 2 AMI
############################################
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


############################################
# EC2 Instance
############################################
resource "aws_instance" "cloth_blog_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  security_groups        = [aws_security_group.cloth_blog_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              systemctl enable docker
              systemctl start docker
              usermod -a -G docker ec2-user
              sleep 10

              REGION=${var.aws_region}
              REPO=${var.image_url}

              # Login to ECR
              aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO

              # Pull the latest image
              docker pull $REPO

              # Stop old container if it exists
              if [ $(docker ps -q -f name=cloth-blog) ]; then
                docker stop cloth-blog
                docker rm cloth-blog
              fi

              # Run the new container
              docker run -d --name cloth-blog -p 80:80 $REPO
              EOF

  tags = {
    Name = "ClothBlog-EC2"
  }
}