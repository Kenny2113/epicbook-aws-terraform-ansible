# Discover available Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Main VPC
resource "aws_vpc" "epicbook_vpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = "production"
    Project     = var.project_name
  }
}

# Public subnet for the application server
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.epicbook_vpc.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
    Tier = "public"
  }
}

# Private subnet 1 for RDS
resource "aws_subnet" "private_db_1" {
  vpc_id            = aws_vpc.epicbook_vpc.id
  cidr_block        = "10.20.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-private-db-1"
    Tier = "private"
  }
}

# Private subnet 2 for RDS
resource "aws_subnet" "private_db_2" {
  vpc_id            = aws_vpc.epicbook_vpc.id
  cidr_block        = "10.20.12.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-private-db-2"
    Tier = "private"
  }
}

# Internet Gateway for public subnet connectivity
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.epicbook_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.epicbook_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate public subnet with public route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Application server security group
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for EpicBook application server"
  vpc_id      = aws_vpc.epicbook_vpc.id

  ingress {
    description = "SSH restricted to administrator IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description = "HTTP web traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# Database security group
resource "aws_security_group" "database" {
  name        = "${var.project_name}-db-sg"
  description = "Allow MySQL only from the application server"
  vpc_id      = aws_vpc.epicbook_vpc.id

  ingress {
    description     = "MySQL from EpicBook application server"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

# Register the dedicated SSH public key with AWS
resource "aws_key_pair" "epicbook" {
  key_name   = "${var.project_name}-key"
  public_key = file(pathexpand(var.public_key_path))

  tags = {
    Name = "${var.project_name}-key"
  }
}
