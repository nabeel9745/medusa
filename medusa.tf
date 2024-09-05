
#Here i manually done everything on an uc2 without using docker image(using userdata scripts)

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
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.my-samplekey.key_name
  

  tags = {
    Name = "medusa"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

 user_data = <<-EOF
              #!/bin/bash
              
              # Update package lists
              sudo apt-get update

              # Install PostgreSQL
              sudo apt-get install -y postgresql postgresql-contrib

              # Configure PostgreSQL
              sudo -u postgres psql -c "CREATE USER medusauser WITH PASSWORD '1111';"
              sudo -u postgres psql -c "CREATE DATABASE medusa; GRANT ALL PRIVILEGES ON DATABASE medusa TO medusauser;"

              # Install Node.js and Medusa
              curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
              sudo apt-get install -y nodejs
              sudo npm install -g @medusajs/medusa-cli
              
              # Setup Medusa
              medusa new medusa-project
              cd medusa-project
              npm install
              medusa develop
              EOF

}

#terraform init(to initialise)
#terraform plan (to view configuration)
#terraform apply(to apply configuration)



#we need to edit the .env file to set your PostgreSQL credentials
#DATABASE_URL=postgres://medusauser:11111@52-91-163-227:5432/medusa


#then

#go to http://52-91-163-227:3000 #to accesss(it is my VM ip)
