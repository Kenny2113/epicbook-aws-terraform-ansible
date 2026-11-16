# Find the latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Generate a strong database password
resource "random_password" "db_password" {
  length  = 24
  special = false
}

# Create the RDS subnet group using private subnets
resource "aws_db_subnet_group" "epicbook" {
  name = "${var.project_name}-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_db_1.id,
    aws_subnet.private_db_2.id
  ]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# Managed MySQL database
resource "aws_db_instance" "epicbook" {
  identifier     = "${var.project_name}-mysql"
  engine         = "mysql"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  port     = 3306

  db_subnet_group_name   = aws_db_subnet_group.epicbook.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false

  multi_az                = false
  backup_retention_period = 0
  deletion_protection     = false
  skip_final_snapshot     = true

  tags = {
    Name        = "${var.project_name}-mysql"
    Environment = "production"
    Project     = var.project_name
  }
}

# Ubuntu application server
resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = aws_key_pair.epicbook.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 12
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = "production"
    Project     = var.project_name
  }
}
