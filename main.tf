# John Tambi DevOps IaC
# Terraform Demo

provider "aws" {
    region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "main_vpc" {
    cidr_block = "10.1.0.0/16"
    tags = {
        Name = "VPC terraform Demo"
    } 
}

# Create a Internet Gateway
resource "aws_internet_gateway" "main_aig" {
    vpc_id = aws_vpc.main_vpc.id
}

# Create a Subnet
resource "aws_subnet" "main_subnet" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.1.10.0/24"
    availability_zone = "us-east-1a"
}

# Create Route Table
resource "aws_route_table" "default_route" {
    vpc_id = aws_vpc.main_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main_aig.id
    }
}

#Create Route Table association

resource "aws_route_table_association" "main_arta" {
    subnet_id = aws_subnet.main_subnet.id
    route_table_id = aws_route_table.default_route.id 
}

# Create ACL
resource "aws_network_acl" "main_allow" {
    vpc_id = aws_vpc.main_vpc.id

    egress {
        protocol = "-1"
        rule_no = 100
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = 0
        to_port = 0
    }

    ingress {
        protocol = "-1"
        rule_no = 200
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = 0
        to_port = 0
    }
}

resource "aws_security_group" "ssh_allow" {
    name = "Terraform Demo - Allow ssh traffic"
    description = "Allows all ssh traffic"
    vpc_id = aws_vpc.main_vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Create Elastic IP
resource "aws_eip" "ip_server" {
    instance = aws_intance.webserver.id
    vpc = true
    depends_on = ["aws_internet_gateway.main_aig"]
}

# Continuar con aws_key_pair

### AMI CENTOS7 ami-02eac2c0129f6376b




