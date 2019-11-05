# John Tambi DevOps IaC
# Terraform Demo

# Provider AWS
provider "aws" {
    region = "us-east-1"
}

# Create AWS VPC

resource "aws_vpc" "main_vpc" {
    cidr_block = "10.1.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = "VPC Terraform Demo"
    }
}

# Create AWS Internet Gateway
resource "aws_internet_gateway" "main_aig" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "Gateway Terraform Demo"
    }
}

# Create AWS Subnet
resource "aws_subnet" "main_subnet" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.1.10.0/24"
    availability_zone = "us-east-1b"
    tags = {
        Name = "Subnet Terraform Demo"
    }
}

# Create AWS Route Table
resource "aws_route_table" "default_route" {
    vpc_id = aws_vpc.main_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main_aig.id
    }
    tags = {
        Name = "Route Table Terraform Demo"
    }
}

# Create AWS Route Table association

resource "aws_route_table_association" "main_rta_subnet_public" {
    route_table_id = aws_route_table.default_route.id
    subnet_id = aws_subnet.main_subnet.id
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

# Create Security Group SSH
resource "aws_security_group" "connection_allow" {
    name = "Terraform Demo - Allow ssh & http traffic"
    description = "Allows all ssh traffic"
    vpc_id = aws_vpc.main_vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 8080
        to_port = 8080
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
    instance = aws_instance.jenkins_server.id
    vpc = true
    depends_on = ["aws_internet_gateway.main_aig"]
}


# Create AWS Key Pair
resource "aws_key_pair" "ssh_default" {
    key_name = "ssh_webserver"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDWpKTQ+kEUhMT8dJzzRwBo51N7xQNe5Fh5UhOz2aikW9MQn+IcegjYegf4+ZLsi4c9wo/qvOniBFgQl7agNE07HQoDsB+2Mw1D8D8DeCqF+kkachlVdFw5WkNjdk1UhNTwUh0njxh6tT939cZl/9gOQ/l7u/YaTVNdtyhyb0i80tffmICOiXYTNVHXJ40ZFrXkqOWkuB60O6PqRrZE+evFoIhfpPwUW1jEEYZKlh+YoVCcRSQIzOdTi2Yla9q0SgxQDAKKODNDGvqJLlTdDxE5oE4vA+/8haJbvfGDurxtpx9IATUeuibyhGRIF0lNB7P6HTTN7GqoGI5rZtv0nJhdmaUYTa25m39a5axa7S4mC3/fa+tCkktIi+v6tQDPiIGHi0+LkgxNs4oR6MkYGQ4E+xJjolvCkQpmRteAz7JCF6zesowPIH0uUfr9aozz3MyPhYram89xAEe8rYj6CElM9pxcDVIfGVUW9Xhkr+y5dmyXHN+PMl2I6Kthn0XTAFM+BIxVDSlthDUv3Buf18SAvzhqLPW1yYZtI3dSGN1FEe/UjafAnA5JhXotRp29a1ytjOxqiuesbT/hkgXORnmGE9aPkCbdXnep3XRGDkHA729lszoBlfSFGIAd83uEJA04jKxcKLf822Ti4uRlTz/EGztpfcx25O4hPnb3pqCXvw== jontambi.business@gmail.com"
}

# Create AWS Instance
resource "aws_instance" "jenkins_server" {
    ami = data.aws_ami.latest_jenkins.id
    availability_zone = "us-east-1b"
    instance_type = "t2.micro"
    key_name = aws_key_pair.ssh_default.key_name
    vpc_security_group_ids = [aws_security_group.connection_allow.id]
    subnet_id = aws_subnet.main_subnet.id

    tags = {
        Name = "jenkins_demo"
    }
}


# AWS Select latest AMI
data "aws_ami" "latest_jenkins" {
    owners = ["179966331834"]
    most_recent = true

    filter {
        name = "state"
        values = ["available"]
    }

    filter {
        name = "tag:Name"
        values = ["jenkins_img"]
    }
}

# AWS Output
output "public_ip" {
    value = aws_eip.ip_server.public_ip
}
