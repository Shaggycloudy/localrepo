terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
  access_key = "
  secret_key = ""
}

# 🔹 VPC
resource "aws_vpc" "myvpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
  }
}

# 🔹 Subnet 1 (Public)
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-1"
  }
}

# 🔹 Subnet 2 (Private)
resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "subnet-2"
  }
}

# 🔹 Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "my-igw"
  }
}

# 🔹 Route Table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "my-rt"
  }
}

# 🔹 Route (Internet Access)
resource "aws_route" "route" {
  route_table_id         = aws_route_table.rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# 🔹 Associate Route Table with Subnet1
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt.id
}

# 🔹 Security Group
resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # HTTP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-sg"
  }
}

# 🔹 EC2 Instance (Subnet1 me)
resource "aws_instance" "myec2" {
  ami                         = "ami-048f4445314bcaa09"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet1.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true
  key_name                    = "your-key-name"

  tags = {
    Name = "my-ec2"
  }
}
