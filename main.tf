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

// The Private Route Table Resource
resource "aws_route_table" "roheem-private-route-table" {
  vpc_id = aws_vpc.roheem-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.roheem-nat-gateway.id
  }
  tags = {
    Name = "roheem-private-route-table"
  }
}

# // Public Subnet Resource
resource "aws_subnet" "roheem-public-subnet1" {
  vpc_id     = aws_vpc.roheem-vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1a"
  tags = {
    Name = "roheem-public-subnet1",
    managedBy = "roheem.olayemi@cecureintel.com"
  }
}

resource "aws_subnet" "roheem-public-subnet2" {
  vpc_id     = aws_vpc.roheem-vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1b"
  tags = {
    Name = "roheem-public-subnet2",
    managedBy = "roheem.olayemi@cecureintel.com"
  }
}

// Private Subnet Resource
resource "aws_subnet" "roheem-private-subnet" {
  vpc_id     = aws_vpc.roheem-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "roheem-private-subnet",
    managedBy = "roheem.olayemi@cecureintel.com"
  }
}

// Public Route Table Association for Public Subnet 1 Resource
resource "aws_route_table_association" "roheem-public1-route-table-association" {
  subnet_id      = aws_subnet.roheem-public-subnet1.id
  route_table_id = aws_route_table.roheem-public-route-table.id
}

// Public Route Table Association for Public Subnet 2 Resource
resource "aws_route_table_association" "roheem-public2-route-table-association" {
  subnet_id      = aws_subnet.roheem-public-subnet2.id
  route_table_id = aws_route_table.roheem-public-route-table.id
}

// Private Route Table Association Resource
resource "aws_route_table_association" "roheem-private-route-table-association" {
  subnet_id      = aws_subnet.roheem-private-subnet.id
  route_table_id = aws_route_table.roheem-private-route-table.id
}

resource "aws_iam_role" "roheem-ec2-ssm-role" {
  name = "roheem-ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "roheem-ee2-ssm-role"
  }
}

resource "aws_iam_role_policy_attachment" "ec2-role-policy-attachment" {
  role       = aws_iam_role.roheem-ec2-ssm-role.name
  # policy_arn = aws_iam_policy.roheem-ec2-ssm-policy.arn
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "roheem-ec2-ssm-profile" {
  name = "roheem-ec2-ssm-profile"
  role = aws_iam_role.roheem-ec2-ssm-role.name
}

// Ubuntu EC2 Instance Resource
resource "aws_instance" "roheem-ec2" {
  ami                     = "ami-04a81a99f5ec58529"
  instance_type           = "t2.micro"
  subnet_id = aws_subnet.roheem-private-subnet.id
  vpc_security_group_ids = [aws_security_group.roheem-server-sg.id]
  iam_instance_profile = aws_iam_instance_profile.roheem-ec2-ssm-profile.name
    tags = {
    Name = "roheem-server",
    managedBy = "roheem.olayemi@cecureintel.com"
  }
}

// Ubuntu Server Security Group Resource
resource "aws_security_group" "roheem-server-sg" {
  vpc_id      = aws_vpc.roheem-vpc.id
  tags = {
    Name = "Ubuntu-ServerSG",
    managedBy = "roheem.olayemi@cecureintel.com"
  }
}

// Inbound Rule (SSH) Security Group Resource for EC2
resource "aws_vpc_security_group_ingress_rule" "server-inbound-rule-ssh" {
  security_group_id = aws_security_group.roheem-server-sg.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

// Inbound Rule (HTTP) Security Group Resource for EC2 Allow traffic via the Load Balancer alone
resource "aws_security_group_rule" "allow_lb_only" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.roheem-lb-sg.id  
  security_group_id        = aws_security_group.roheem-server-sg.id 
}

// Outbound Rule Security Group Resource
resource "aws_vpc_security_group_egress_rule" "server-outbound-rule" {
  security_group_id = aws_security_group.roheem-server-sg.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  ip_protocol = -1
  to_port     = 0
}
