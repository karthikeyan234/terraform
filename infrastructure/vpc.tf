provider "aws" {
  region                  =  var.region
  shared_credentials_file = "$HOME/.aws/credentials"
}

terraform {
  backend "s3" {}
}

/*
* CREATE A VPC
*/
resource "aws_vpc" "production-vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  enable_dns_hostnames = true

  tags = {
    Name = "Production-Terraform-VPC-Modify"
  }
}
/*
* CREATE INTERNET GATEWAY
*/
resource "aws_internet_gateway" "production-igw" {
  vpc_id = aws_vpc.production-vpc.id

  tags = {
    Name = "Production-IGW"
  }
}
/*
* CREATE PUBLIC SUBNET 1
*/
resource "aws_subnet" "public-subnet-1" {
  cidr_block        = var.public_subnet_1_cidr
  vpc_id            = aws_vpc.production-vpc.id
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-1"
  }
}
/*
* CREATE PUBLIC SUBNET 2
*/
resource "aws_subnet" "public-subnet-2" {
  cidr_block        = var.public_subnet_2_cidr
  vpc_id            = aws_vpc.production-vpc.id
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-2"
  }
}

# resource "aws_subnet" "public-subnet-3" {
#   cidr_block        = var.public_subnet_3_cidr
#   vpc_id            = aws_vpc.production-vpc.id
#   availability_zone = "ap-south-1a"
#
#   tags = {
#     Name = "Public-Subnet-3"
#   }
# }
/*
* CREATE PRIVATE SUBNET 1
*/
resource "aws_subnet" "private-subnet-1" {
  cidr_block        = var.private_subnet_1_cidr
  vpc_id            = aws_vpc.production-vpc.id
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Private-Subnet-1"
  }
}
/*
* CREATE PRIVATE SUBNET 2
*/
resource "aws_subnet" "private-subnet-2" {
  cidr_block        = var.private_subnet_2_cidr
  vpc_id            = aws_vpc.production-vpc.id
  availability_zone = "ap-south-1b"

  tags = {
    Name = "Private-Subnet-2"
  }
}

# resource "aws_subnet" "private-subnet-3" {
#   cidr_block        = var.private_subnet_3_cidr
#   vpc_id            = aws_vpc.production-vpc.id
#   availability_zone = "ap-south-1a"
#
#   tags = {
#     Name = "Private-Subnet-3"
#   }
# }
/*
* CREATE ELASTIC IP
*/
resource "aws_eip" "elastic-ip-for-nat-gw" {
  vpc                       = true
  #associate_with_private_ip = "10.0.0.5"
  tags = {
    Name = "Production-EIP"
  }
}
/*
* CREATE NAT GATEWAY
*/
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.elastic-ip-for-nat-gw.id
  subnet_id     = aws_subnet.public-subnet-1.id

  tags = {
    Name = "Production-NAT-GW"
  }

  depends_on = [aws_eip.elastic-ip-for-nat-gw]
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.production-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.production-igw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.production-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name = "Private-Route-Table"
  }
}

resource "aws_route_table_association" "public-route-1-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-1.id

}

resource "aws_route_table_association" "public-route-2-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-2.id
}

# resource "aws_route_table_association" "public-route-3-association" {
#   route_table_id = aws_route_table.public-route-table.id
#   subnet_id      = aws_subnet.public-subnet-3.id
# }

resource "aws_route_table_association" "private-route-1-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet-1.id
}

resource "aws_route_table_association" "private-route-2-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet-2.id
}

# resource "aws_route_table_association" "private-route-3-association" {
#   route_table_id = aws_route_table.private-route-table.id
#   subnet_id      = aws_subnet.private-subnet-3.id
# }



# resource "aws_route" "nat-gw-route" {
#   route_table_id         = aws_route_table.private-route-table.id
#   nat_gateway_id         = aws_nat_gateway.nat-gw.id
#   destination_cidr_block = "0.0.0.0/0"
# }



# resource "aws_route" "public-internet-igw-route" {
#   route_table_id         = aws_route_table.public-route-table.id
#   gateway_id             = aws_internet_gateway.production-igw.id
#   destination_cidr_block = "0.0.0.0/0"
# }
