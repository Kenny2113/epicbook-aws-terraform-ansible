variable "aws_region" {
  description = "AWS deployment region"
  type        = string
}

variable "project_name" {
  description = "Project identifier"
  type        = string
  default     = "epicbook-prod"
}

variable "ssh_allowed_cidr" {
  description = "Public IP allowed to connect to EC2 over SSH"
  type        = string
}

variable "public_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "~/.ssh/epicbook-prod-key.pub"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "EpicBook database name"
  type        = string
  default     = "epicbook"
}

variable "db_username" {
  description = "EpicBook database administrator username"
  type        = string
  default     = "epicbook_admin"
}
