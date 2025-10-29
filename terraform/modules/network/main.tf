# Notes:
# - Internet Gateway attached to the VPC is required for public subnets.
# - 3 Subnets needed:
#   - 2 Public Subnets for web tier (in different AZs)
#   - 1 Public Subnet for the Jenkins server (can be in any AZ)

# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.module_prefix}-vpc"
  }
}

# See:
# - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc



# Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.module_prefix}-igw"
  }
}

# See:
# - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway



# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {
  state = "available"
}

# See:
# - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones

#----- Public Subnets
#-- Public Subnet AZ A
resource "aws_subnet" "pub_sub_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.pub_sub_a_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.module_prefix}-pub_sub_a"
  }
}
#-- Public Subnet AZ B
resource "aws_subnet" "pub_sub_b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.pub_sub_b_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.module_prefix}-pub_sub_b"
  }
}
#-- Jenkins Server Subnet AZ A
resource "aws_subnet" "jenkins_sub_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.jenkins_sub_a_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.module_prefix}-jenkins-sub-a"
  }
}

# See:
# - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet



# Route Table for Public Subnets (attach Internet Gateway to VPC)
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${var.module_prefix}-public-rt"
  }
}
# associate public subnet pub_sub_a to "public route table"
resource "aws_route_table_association" "pub_sub_a_route_table_association" {
  subnet_id      = aws_subnet.pub_sub_a.id
  route_table_id = aws_route_table.public_route_table.id
}
# associate public subnet pub_sub_b to "public route table"
resource "aws_route_table_association" "pub_sub_b_route_table_association" {
  subnet_id      = aws_subnet.pub_sub_b.id
  route_table_id = aws_route_table.public_route_table.id
}
# associate jenkins subnet jenkins_sub_a to "public route table"
resource "aws_route_table_association" "jenkins_sub_a_route_table_association" {
  subnet_id      = aws_subnet.jenkins_sub_a.id
  route_table_id = aws_route_table.public_route_table.id
}
