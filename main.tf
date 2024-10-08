resource "aws_vpc" "dev_vpc" {
  cidr_block           = "10.172.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.env}"
  }
}

resource "aws_subnet" "dev_public_subnet" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.172.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1a"

  tags = {
    Name = "${var.env}_public"
  }
}

resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "${var.env}_igw"
  }
}

resource "aws_route_table" "dev_rt" {
  vpc_id = aws_vpc.dev_vpc.id

  route = []

  tags = {
    Name = "${var.env}_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id            = aws_route_table.dev_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.dev_igw.id
}

resource "aws_route_table_association" "dev_public_asoc" {
  subnet_id      = aws_subnet.dev_public_subnet.id
  route_table_id = aws_route_table.dev_rt.id
}

resource "aws_security_group" "dev_sg" {
  name        = "${var.env}_sg"
  description = "dev sercurity group"
  vpc_id      = aws_vpc.dev_vpc.id

  tags = {
    Name = "${var.env}_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "dev_allow_http_ipv4" {
  security_group_id = aws_security_group.dev_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


resource "aws_vpc_security_group_egress_rule" "dev_allow_all_ipv4" {
  security_group_id = aws_security_group.dev_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 0
  ip_protocol       = "tcp"
  to_port           = 0
}

resource "aws_key_pair" "dev_auth" {
  key_name   = "${var.env}-key"
  public_key = file("~/.ssh/tfdev.pub")
}


resource "aws_instance" "dev_instance" {
  instance_type = "t3.micro"
  ami = data.aws_ami.server_ami.id

  tags = {
    name = "${var.env}_instance"
  }

  key_name = aws_key_pair.dev_auth.id

  vpc_security_group_ids = [aws_security_group.dev_sg.id]

  subnet_id   = aws_subnet.dev_public_subnet.id

  user_data = file("userdata.tpl")

  provisioner "local-exec" {

    command = templatefile("win-ssh-config.tpl", {
              hostname = self.public_ip,
              user = "ubuntu",
              identityfile = "~/.ssh/tfdev"
    }) 
    interpreter = ["Powershell", "-Command"]
  }


}