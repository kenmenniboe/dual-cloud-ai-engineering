terraform {
  required_version = ">= 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "terraform-lab"
}

resource "aws_instance" "my_first_ec2" {
  ami           = "ami-096ef200a877f36af"
  instance_type = "t3.micro"

  tags = {
    Name    = "first-terraform-ec2"
    Project = "terraform-block1"
  }
}