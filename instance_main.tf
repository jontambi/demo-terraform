# John Tambi DevOps IaC
# Terraform Demo

# Provider AWS
provider "aws" {
    region = "us-east-1"
}

data "aws_ami" "jenkins-ec2" {
    filter {
        name = "state"
        values = ["available"]
    }

    filter {
        name = "tag:Name"
        values = ["jenkins_img"]
    }

    most_recent = true

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

# Create Security Group HTTP
resource "aws_security_group" "http_allow" {
    name = "Terraform Demo - Allow http traffic"
    description = "Allows all http traffic Jenkins"
    vpc_id = aws_vpc.main_vpc.id

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

#    egress {
#        from_port = 0
#        to_port = 0
#        protocol = "tcp"
#        cidr_blocks = ["0.0.0.0/0"]
#    }
}

# Create Elastic IP
resource "aws_eip" "ip_server" {
    instance = aws_instance.webserver.id
    vpc = true
    depends_on = ["aws_internet_gateway.main_aig"]
}



#https://itnext.io/immutable-infrastructure-using-packer-ansible-and-terraform-7ca6f79582b8