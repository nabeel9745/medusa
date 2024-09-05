
# here i download the medusa image from dockerhub and run it

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1",
  access_key = "",
  secret_key = ""
}

# To create Private Key
resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

variable "key_name" {
  description = "Name of the SSH key pair"
}

# This Key Pair is to Connect EC2 via SSH
resource "aws_key_pair" "my-samplekey" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

# Save PEM file locally
resource "local_file" "private_key" {
  content  = tls_private_key.rsa_4096.private_key_pem
  filename = var.key_name
}

# then we could create a security group
resource "aws_security_group" "secure_ec2" {
  name        = "secure_ec2"
  description = "Security group for EC2"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "http"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    description = "Allow traffic on port 9000"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
resource "aws_instance" "medusa" {
  ami                    = "ami-0e86e20dae9224db88"
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.my-samplekey.key_name
  

  tags = {
    Name = "medusa"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }


  # User data to configure the instance
  user_data = <<-EOF
              #!/bin/bash
              # Update and install required packages
              apt-get update
              apt-get upgrade -y
              apt-get install -y docker.io postgresql postgresql-contrib

              # Start Docker service
              systemctl start docker
              systemctl enable docker

              # Start PostgreSQL service
              systemctl start postgresql
              systemctl enable postgresql

              # Configure PostgreSQL
              sudo -u postgres psql -c "CREATE USER medusa WITH PASSWORD 'your_password';"
              sudo -u postgres psql -c "CREATE DATABASE medusa_db WITH OWNER medusa;"

              EOF
}

#we need to edit the .env file to set your PostgreSQL credentials
#DATABASE_URL=postgres://medusauser:11111@52-91-163-227:5432/medusa
#and
 # Pull and run Medusa Docker image
  #            ddocker pull linuxserver/medusa
   #           docker run -d -p 9000:9000 \
    #            -e DATABASE_URL=postgres://medusa:1111@52-91-163-227:5432/medusa \
     #           linuxserver/medusa:latest

#need to Create a docker-compose.yml File:
///version: '3'

services:
  medusa:
    image: medusajs/medusa:latest
    container_name: medusa
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgres://medusauser:11111@52-91-163-227:5432/medusa_db
    depends_on:
      - postgres

  postgres:
    image: postgres:13
    container_name: postgres
    environment:
      POSTGRES_USER: medusauser
      POSTGRES_PASSWORD: 11111
      POSTGRES_DB: medusa
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
///