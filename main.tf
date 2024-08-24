# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

//The VPC Resource Block
resource "aws_vpc" "roheem-vpc" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "roheem-vpc",
    managedBy = "roheem.olayemi@cecureintel.com"
  }
}

  //The Internet Gateway Resource
  resource "aws_internet_gateway" "roheem-igw" {
    vpc_id = aws_vpc.roheem-vpc.id
    tags = {
      Name = "roheem-igw",
      managedBy = "roheem.olayemi@cecureintel.com"
    }
  }

// The Public Route Table Resource
resource "aws_route_table" "roheem-public-route-table" {
  vpc_id = aws_vpc.roheem-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.roheem-igw.id
  }
  tags = {
    Name = "roheem-public-route-table"
  }
}

// Elastic IP Resource
resource "aws_eip" "roheem-eip" {
  domain   = "vpc"
   tags = {
    Name = "Roheem-EIP"
  }
}

// NAT Gateway Resource
resource "aws_nat_gateway" "roheem-nat-gateway" {
  allocation_id = aws_eip.roheem-eip.id
  subnet_id     = aws_subnet.roheem-public-subnet1.id

  tags = {
    Name = "Roheem-NATGW"
  }
  depends_on = [aws_internet_gateway.roheem-igw]
}