variable instance_name {
  description = "Name Of the EC2 instance"
  type = string
  default = "keycloak-server"
}

variable "aws_region" {
  description = "AWS Region In which Resources Will Be Deployed"
  type = string
  default = "ap-south-1"  
}

variable "instance_type" {
  description = "Instance Type "
  type = string
  default = "t2.xlarge"  
}

variable "instance_keypair" {
  description = "SSH KeyPair For EC2 Instance"
  type = string
  default = "puneetjoshipsedaily"  
}

variable "kc_security_group" {
  description = "Security Group Name For EC2"
  type = string
  default = "hol-default-sg"
}
variable "local_ip" {
  description = "IPV4 Address User's Local Machine"
  type = string
  default = "0.0.0.0/0"
}
variable "amis" {
  type = map(string)
  default = {
    "us-east-2" = "ami-033adaf0b583374d4"
    "us-east-1" = "ami-0aedf6b1cb669b4c7"
    "us-west-1" = "ami-0bcd12d19d926f8e9"
    "us-west-2" = "ami-04f798ca92cc13f74"
    "ap-south-1" = "ami-09f129ee53d3523c0"
    "ap-southeast-1" = "ami-03bfba2e75432064e"
    "ap-southeast-2" = "ami-0264ead5294ad1773"
    "eu-central-1" = "ami-0afcbcee3dfbce929"
    "eu-west-1" = "ami-00d464afa64e1fc69"
    "eu-west-2" = "ami-0de2f45684e59282c"
  }
}