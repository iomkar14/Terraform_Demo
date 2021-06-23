provider "aws" {
  region  = "${var.aws_region}"
}
#-------VPC------------------------
resource "aws_vpc" "demo_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "demo_vpc"
  }
}
#-------IGW-----------------------------

resource "aws_internet_gateway" "demo_igw" {
  vpc_id = "${aws_vpc.demo_vpc.id}"

  tags = {
    Name = "demo_igw"
  }
}


#------Subnets----------------------

resource "aws_subnet" "demo_public" {
  vpc_id                  = "${aws_vpc.demo_vpc.id}"
  cidr_block              = "${var.cidrs["public"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  tags = {
    Name = "demo_public"
  }
}

resource "aws_subnet" "demo_private" {
  vpc_id                  = "${aws_vpc.demo_vpc.id}"
  cidr_block              = "${var.cidrs["private"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  tags = {
    Name = "demo_private"
  }
}
 
#--------NAT Gateway--------------
#eip
resource "aws_eip" "demo_eip" {
vpc      = true
}
resource "aws_nat_gateway" "demo_nat"{
  allocation_id = "${aws_eip.demo_eip.id}"
  subnet_id = "${aws_subnet.demo_public.id}"
  depends_on = ["aws_internet_gateway.demo_igw"]
}

#------Route tables------------------

resource "aws_route_table" "demo_public_rt" {
  vpc_id = "${aws_vpc.demo_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.demo_igw.id}"
  }
  tags = {
    Name = "demo_public_rt"
  }
}

resource "aws_route_table" "demo_private_rt" {
 vpc_id = "${aws_vpc.demo_vpc.id}"
 route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id  = "${aws_nat_gateway.demo_nat.id}"
 }
 tags = {
    Name = "demo_private"
 }
}

#--------Subnet-Association-in-Routetable---------

resource "aws_route_table_association" "demo_public_association" {
  subnet_id      = "${aws_subnet.demo_public.id}"
  route_table_id = "${aws_route_table.demo_public_rt.id}"
}

resource "aws_route_table_association" "demo_private_association" {
  subnet_id      = "${aws_subnet.demo_private.id}"
  route_table_id = "${aws_route_table.demo_private_rt.id}"
}

#------Security-Groups------------------------
resource "aws_security_group" "demo_public_sg" {
  name        = "demo_public_sg"
  description = "Used for access to dev instance jenkins host"
  vpc_id      = "${aws_vpc.demo_vpc.id}"

  #ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.localip}"]
  }
  #http
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${var.localip}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#private-security-group
resource "aws_security_group" "demo_private_sg" {
  name        = "demo_private_sg"
  description = "Used for private instances"
  vpc_id      = "${aws_vpc.demo_vpc.id}"

  #Access from VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#-----------DEV-Server------------------
#key-pair
resource "aws_key_pair" "demo_auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

#Jenkins_instance
resource "aws_instance" "demo_jenkins_ansible" {
  instance_type = "${var.dev_instance_type}"
  ami           = "${var.dev_ami}"
  tags = {
    Name = "demo_jenkins"
  }
  key_name               = "${aws_key_pair.demo_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.demo_public_sg.id}"]
  subnet_id              = "${aws_subnet.demo_public.id}"
  user_data              = "${file("jenkins_userdata")}"
}

#Deployment_instance
resource "aws_instance" "demo_deployment" {
  instance_type = "${var.dev_instance_type}"
  ami           = "${var.dev_ami}"
  tags = {
    Name = "demo_deployment"
  }
  key_name               = "${aws_key_pair.demo_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.demo_private_sg.id}"]
  subnet_id              = "${aws_subnet.demo_private.id}"
  user_data              = "${file("docker_userdata")}"
}