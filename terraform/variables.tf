############################################
# Variables
############################################
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  default     = "terraform-key"  # <-- Replace with your actual key name
}

variable "image_url" {
  description = "ECR repository URI with image tag"
  type        = string
  default     = "312596057535.dkr.ecr.us-east-1.amazonaws.com/cloth-blog:latest"
}