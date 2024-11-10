# Specfying the AWS provider with region configuration
provider "aws" {
  region = "eu-west-1" 
}

# Defining the Virtual Private Cloud (VPC)
resource "aws_vpc" "cloud_automation_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "CloudAutomationVPC"
  }
}

# Defining a public subnet within the VPC
resource "aws_subnet" "cloud_automation_subnet" {
  vpc_id            = aws_vpc.cloud_automation_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"  # Specifying availability zone
  map_public_ip_on_launch = true  # Ensures instances get a public IP address
  tags = {
    Name = "CloudAutomationSubnet"
  }
}

# Creating an Internet Gateway to allow outbound traffic
resource "aws_internet_gateway" "cloud_automation_igw" {
  vpc_id = aws_vpc.cloud_automation_vpc.id
  tags = {
    Name = "CloudAutomationInternetGateway"
  }
}

# Creating a Route Table for routing internet traffic
resource "aws_route_table" "cloud_automation_route_table" {
  vpc_id = aws_vpc.cloud_automation_vpc.id

  route {
    cidr_block = "0.0.0.0/0"  # Default route to internet
    gateway_id = aws_internet_gateway.cloud_automation_igw.id
  }

  tags = {
    Name = "CloudAutomationRouteTable"
  }
}

# Associates the Route Table with the subnet
resource "aws_route_table_association" "cloud_automation_route_table_association" {
  subnet_id      = aws_subnet.cloud_automation_subnet.id
  route_table_id = aws_route_table.cloud_automation_route_table.id
}

# Defines a Security Group with rules for SSH and HTTP access
resource "aws_security_group" "cloud_automation_sg" {
  vpc_id     = aws_vpc.cloud_automation_vpc.id
  description = "Allow SSH and HTTP traffic"

  # Ingress rule for SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allows SSH access from anywhere (change for security)
  }

  # Ingress rule for HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allows HTTP access from anywhere
  }

  # Egress rule (allow all outbound traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "CloudAutomationSecurityGroup"
  }
}

# Define an EC2 instance within the subnet
resource "aws_instance" "cloud_automation_instance" {
  ami             = "ami-0d64bb532e0502c46"   # ubuntu for eu-west-1 (check region for correct AMI)
  instance_type   = "t2.micro"                # Free-tier eligible instance type
  subnet_id       = aws_subnet.cloud_automation_subnet.id
  security_groups = [aws_security_group.cloud_automation_sg.id]  # Attach the security group
  key_name        = "network"

  tags = {
    Name = "CloudAutomationInstance"
  }
}

# Output the instance's public IP address
output "instance_public_ip" {
  value = aws_instance.cloud_automation_instance.public_ip
}

