# Terraform Block
terraform {
  required_version = "1.4.6"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.65.0"
    }
  }
}
# Provider Block
provider "aws" {
  region = var.aws_region
  # profile = "default" 
}
resource "aws_instance" "keycloak-server" {
  ami = var.amis[var.aws_region]
  instance_type = "${var.instance_type}"
  user_data = file("${path.module}/install-docker.sh")
  key_name = "${var.instance_keypair}"
  security_groups = [ aws_security_group.vpc-ssh-web.name ]
  tags = {
    "Name" = var.instance_name
  }
  provisioner "file" {
    source      = "cloudera-newco-wshps.png"
    destination = "/tmp/cloudera-newco-wshps.png"

    connection {
      type        = "ssh"
      user        = "centos"
      private_key = "${file("/userconfig/${var.instance_keypair}.pem")}"
      host        = "${self.public_dns}"
    }
  }
  provisioner "file" {
    source      = "cloudera-wshps.png"
    destination = "/tmp/cloudera-wshps.png"

    connection {
      type        = "ssh"
      user        = "centos"
      private_key = "${file("/userconfig/${var.instance_keypair}.pem")}"
      host        = "${self.public_dns}"
    }
  }
  
}


resource aws_eip "kc_elastic_ip" {
instance = aws_instance.keycloak-server.id
}

resource "aws_security_group" "vpc-ssh-web" {
  name = "${var.kc_security_group}"
  description = "Allow SSH Connection from specific IP"
  ingress {
    description = "Allow SSH Traffic"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "${var.local_ip}" ]
  }
  ingress {
    description = "Allow web Traffic"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [ "${var.local_ip}" ]
  }
  ingress {
    description = "Allow web Traffic"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "${var.local_ip}" ]
  }
  egress {
    description = "Allow All Outbound Connection"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# # Security Group For Web Traffic
# resource "aws_security_group" "vpc-web" {
#   name = "${var.kc_security_group}-web"
#   description = "Allow Web Traffic"
#   ingress {
#     description = "Allow web Traffic"
#     from_port = 80
#     to_port = 80
#     protocol = "tcp"
#     cidr_blocks = [ "${var.local_ip}" ]
#   }
#   ingress {
#     description = "Allow web Traffic"
#     from_port = 443
#     to_port = 443
#     protocol = "tcp"
#     cidr_blocks = [ "${var.local_ip}" ]
#   }
#   egress {
#     description = "Allow All Outbound Connection"
#     from_port = 0
#     to_port = 0
#     protocol = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
  
# }