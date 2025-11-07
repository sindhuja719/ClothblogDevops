output "ec2_public_ip" {
  description = "Public IP address of the Cloth Blog EC2 instance"
  value       = aws_instance.cloth_blog_ec2.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the Cloth Blog EC2 instance"
  value       = aws_instance.cloth_blog_ec2.public_dns
}
output "public_ip" {
  value = aws_instance.cloth_blog_ec2.public_ip
}
