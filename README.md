# EpicBook – AWS Infrastructure Deployment with Terraform and Ansible

## Project Overview

This project demonstrates the deployment of the EpicBook application on AWS using Infrastructure as Code (IaC) and configuration management.

Terraform provisions the AWS infrastructure, while Ansible automates server configuration and application deployment.

The application runs on an Ubuntu EC2 instance, with Nginx acting as a reverse proxy and PM2 managing the Node.js application process. The application uses an Amazon RDS MySQL database.

## Architecture

```text
                   Internet
                      |
                      |
                 Nginx (Port 80)
                      |
                      |
              Ubuntu EC2 Instance
                      |
                Node.js App
                 PM2 (8080)
                      |
                      |
              Amazon RDS MySQL
               Private Subnets
```

## Technologies Used

- AWS EC2
- Amazon RDS MySQL
- Amazon VPC
- AWS Security Groups
- Terraform
- Ansible
- Python Virtual Environment (`venv`)
- Ubuntu Linux
- Node.js
- PM2
- Nginx
- Git and GitHub

## Project Structure

```text
epicbook-prod/
│
├── ansible/
│   ├── ansible.cfg
│   ├── site.yml
│   ├── common-setup.yml
│   ├── inventory.example.ini
│   │
│   ├── group_vars/
│   │   └── web/
│   │       └── vars.example.yml
│   │
│   └── roles/
│       ├── common/
│       │   └── tasks/main.yml
│       │
│       ├── nginx/
│       │   ├── tasks/main.yml
│       │   ├── handlers/main.yml
│       │   └── templates/epicbook.conf.j2
│       │
│       └── epicbook/
│           ├── tasks/main.yml
│           └── templates/.env.j2
│
├── terraform/
│   └── aws/
│       ├── main.tf
│       ├── provider.tf
│       ├── versions.tf
│       ├── variables.tf
│       ├── compute_database.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
│
├── .gitignore
└── README.md
```

## 1. Local Ansible Control Environment Setup

I used WSL Ubuntu as my local Ansible control machine.

Instead of installing Ansible directly into the system Python environment, I created a Python virtual environment named `.venv`. This keeps the project's Python dependencies isolated.

### Install prerequisites

```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip openssh-client
```

### Create the project directory

```bash
mkdir -p ~/epicbook-prod
cd ~/epicbook-prod
```

### Create the Python virtual environment

```bash
python3 -m venv .venv
```

### Activate the virtual environment

```bash
source .venv/bin/activate
```

Once activated, the terminal displays `(.venv)`.

### Upgrade pip and install Ansible

```bash
python -m pip install --upgrade pip
python -m pip install ansible
```

### Verify Ansible installation

```bash
ansible --version
```

### Reactivate the environment in future sessions

```bash
cd ~/epicbook-prod
source .venv/bin/activate
```

The `.venv/` directory is excluded from Git because it contains locally installed dependencies. It can be recreated using the commands above.

**Important:** Ansible runs from the local WSL Ubuntu environment and connects remotely to the AWS EC2 instance through SSH. Terraform is installed and used separately.

## 2. AWS Infrastructure Provisioning with Terraform

Terraform was used to provision the AWS infrastructure required by the application.

The infrastructure includes:

- VPC and networking resources.
- Public subnet for the application server.
- Private database subnets.
- Internet Gateway and routing.
- Security groups controlling network access.
- Ubuntu EC2 instance.
- Amazon RDS MySQL database.
- SSH key pair configuration.

### Configure Terraform

Navigate to the Terraform directory:

```bash
cd ~/epicbook-prod/terraform/aws
```

Create your local variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your own configuration. In particular, provide your public IP address in CIDR notation for SSH access.

### Initialize Terraform

```bash
terraform init
```

### Validate the configuration

```bash
terraform validate
```

### Review the execution plan

```bash
terraform plan
```

### Provision the infrastructure

```bash
terraform apply
```

Review the plan and confirm when prompted.

Terraform outputs provide useful deployment information, including the EC2 public IP and RDS connection details.

## 3. Ansible Configuration and Application Deployment

Ansible was used to automate the configuration of the EC2 instance and deployment of the EpicBook application.

The project uses the following roles:

- **Common:** Base server configuration and required packages.
- **Nginx:** Installation and configuration of Nginx as a reverse proxy.
- **EpicBook:** Application setup, Node.js dependencies, environment configuration and PM2 process management.

### Configure the Ansible inventory

Navigate to the Ansible directory:

```bash
cd ~/epicbook-prod/ansible
```

Create your local inventory:

```bash
cp inventory.example.ini inventory.ini
```

Update the inventory with your EC2 public IP and the correct SSH private key path.

### Configure application variables

Create your local variables file:

```bash
cp group_vars/web/vars.example.yml group_vars/web/vars.yml
```

Update the variables with your actual deployment configuration, including the RDS endpoint and server details.

### Configure Ansible Vault

The database password is protected using Ansible Vault.

Create or configure the encrypted Vault variables file:

```bash
ansible-vault create group_vars/web/vault.yml
```

Add the encrypted variable:

```yaml
vault_db_password: YOUR_DATABASE_PASSWORD
```

The application variables reference this Vault variable rather than storing the database password in plain text.

### Test SSH connectivity

```bash
ansible web -i inventory.ini -m ping
```

### Check playbook syntax

```bash
ansible-playbook -i inventory.ini site.yml --syntax-check --ask-vault-pass
```

### Deploy the application

```bash
ansible-playbook -i inventory.ini site.yml --ask-vault-pass
```

Ansible connects to the EC2 instance and executes the deployment tasks defined in the playbooks and roles.

## 4. Application Configuration

The application is deployed as a Node.js service.

- **Application port:** 8080
- **Process manager:** PM2
- **Reverse proxy:** Nginx
- **Public web access:** HTTP port 80
- **Database:** Amazon RDS MySQL

Ansible uses a Jinja2 environment template to generate the application's `.env` file on the EC2 instance.

The template uses variables for the database host, username, password, database name and application port.

PM2 manages the application process, while Nginx forwards incoming HTTP requests to the application running on port 8080.

## 5. Deployment Verification

After deployment, the following checks can be used to verify the services on the EC2 instance:

```bash
sudo systemctl status nginx
```

```bash
pm2 status
```

```bash
curl http://localhost:8080
```

The application can be accessed through the EC2 public IP or configured domain:

```text
http://YOUR_EC2_PUBLIC_IP
```

Replace the placeholder with your own deployment address.

## 6. Security Considerations

Security measures implemented in the project include:

- Restricting SSH access through a configurable IP address in the security group.
- Keeping the database in private subnets.
- Separating application and database network access.
- Using Ansible Vault to encrypt sensitive database credentials.
- Excluding SSH private keys, Terraform state files, local variables and secret files from Git.
- Providing example configuration files instead of publishing actual credentials.

Never commit real passwords, private keys, `.env` files, `terraform.tfstate` files or unencrypted Vault credentials.

## 7. Key Learning Outcomes

Through this project, I gained practical experience in:

- Provisioning AWS infrastructure with Terraform.
- Managing VPC networking, subnets and security groups.
- Deploying and configuring Ubuntu EC2 instances.
- Provisioning Amazon RDS MySQL.
- Creating and managing Python virtual environments.
- Using Ansible inventories, playbooks, roles and Jinja2 templates.
- Protecting sensitive variables with Ansible Vault.
- Deploying Node.js applications with PM2.
- Configuring Nginx as a reverse proxy.
- Managing infrastructure and application deployment through automation.

## Application Source

The EpicBook application source code used for this deployment is available at:

https://github.com/pravinmishraaws/theepicbook

This repository contains my infrastructure provisioning and deployment automation configuration.
