output "dev_ip" {
  value       = aws_instance.dev_instance.public_ip
  description = "EC2 public IPv4"
}
