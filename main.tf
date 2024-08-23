resource "aws_vpc" "dev_main" {
  cidr_block = "10.172.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "dev"
  }
}