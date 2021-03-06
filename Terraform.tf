//create AWS provider 
provider "aws" {
    //aws profile defined in aws cli
  profile    = "personalAWS" // Decomment this line to use this file locally
  version = "~> 2.9"
    //aws region selection
  region     = "eu-west-1"
}

//create s3 tfstate location cl
terraform {
  backend "s3"{
    bucket         = "terraform-bucket-sonic0" # Change it based on your preferences
    key            = "terraform-state/terraform.tfstate" # Change it based on your preferences
    dynamodb_table = "terraform_state_lock"
    region         = "eu-west-1"
    profile        = "personalAWS"
  }
}


//create VPC 
resource "aws_vpc" "TerraformTestVPC" {
  cidr_block       = "20.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "TerraformTest-VPC"
  }
}

//create Internet Gateway
resource "aws_internet_gateway" "igwTerraformTest" {
  vpc_id = aws_vpc.TerraformTestVPC.id

  tags = {
    Name = "igwTerraformTest"
  }
}

// The two subnet must be split across multiple Availability Zones within the same region.
// https://github.com/terraform-providers/terraform-provider-aws/issues/3223

//create public Subnet
resource "aws_subnet" "TerraformTestPublicSubnet" {
  vpc_id     = aws_vpc.TerraformTestVPC.id
  cidr_block = "20.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "TerraformTestPublicSubnet"
  }
}

//create public Subnet for RDS
resource "aws_subnet" "TerraformTestPublicSubnet2" {
  vpc_id     = aws_vpc.TerraformTestVPC.id
  cidr_block = "20.0.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "TerraformTestPublicSubnet2"
  }
}

//create Route Table with allocation to Internet Gateway
resource "aws_route_table" "routeTableTerraformTest" {
  vpc_id = aws_vpc.TerraformTestVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igwTerraformTest.id
  }

  tags = {
    Name = "routeTableTerraformTest"
  }
}

//create association RouteTable to Subnet
resource "aws_route_table_association" "aRouteTableSubnet" {
  subnet_id      = aws_subnet.TerraformTestPublicSubnet.id
  route_table_id = aws_route_table.routeTableTerraformTest.id
}

resource "aws_route_table_association" "aRouteTableSubnet2" {
  subnet_id      = aws_subnet.TerraformTestPublicSubnet2.id
  route_table_id = aws_route_table.routeTableTerraformTest.id
}

//create Security Group Web + SSH
resource "aws_security_group" "secGroupTerraformTestWebSSH" {
  name        = "secGroupTerraformTestWebSSH"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.TerraformTestVPC.id
  
  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "secGroupTerraformTestWebSSH"
  }
}

//create security group access MYSQL
resource "aws_security_group" "secGroupTerraformTestMYSQL" {
  name        = "secGroupTerraformTestMYSQL"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.TerraformTestVPC.id
  
  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    security_groups = [aws_security_group.secGroupTerraformTestWebSSH.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "secGroupTerraformTestMYSQL"
  }
}

/*resource "aws_iam_role" "roleTerraformTest" {
  name = "roleTerraformTest"
  //path = "/"

  assume_role_policy = <<-EOF
                        {
                            "Version": "2012-10-17",
                            "Statement": [
                                {
                                    "Action": "ssm:*",
                                    "Resource": "arn:aws:ssm:*:*:parameter/inventory-app/*", 
                                    "Effect": "Allow"
                                }
                            ]
                        }
                        EOF
}*/

resource "aws_iam_instance_profile" "instanceProfileTerraformTest" {
  name = "instanceProfileTerraformTest"
  role = "Inventory-App-Role" # You Must create this role in your AWS account
}

//create EC2-ec2TerraformTestWebApp user data local variable
variable "userdataEC2" {
    type = string
    default  = <<-EOF
                #!/bin/bash
                yum install -y httpd mysql 
                amazon-linux-extras install -y php7.2 
                wget https://us-west-2-tcprod.s3.amazonaws.com/courses/ILT-TF-100-ARCHIT/v6.4.1/lab-2-webapp/scripts/inventory-app.zip 
                unzip inventory-app.zip -d /var/www/html/ 
                wget https://github.com/aws/aws-sdk-php/releases/download/3.62.3/aws.zip 
                unzip aws -d /var/www/html 
                chkconfig httpd on 
                service httpd start
                EOF
}

//create EC2 Apps
resource "aws_instance" "ec2TerraformTestWebApp" {
    //aws AMI selection -- Amazon Linux 2
  ami = "ami-099a8245f5daa82bf"

    //aws EC2 instance type, t2.micro for free tier
  instance_type                 = "t2.micro"
  key_name                      = "testkeypair" # You must create this key pairs on your AWS
  subnet_id                     = aws_subnet.TerraformTestPublicSubnet.id
  vpc_security_group_ids        = [aws_security_group.secGroupTerraformTestWebSSH.id]
  //user_data_base64            = "${base64encode(var.userdataEC2)}"
  user_data                     = var.userdataEC2
  iam_instance_profile          =  aws_iam_instance_profile.instanceProfileTerraformTest.name
  tags = {
    Name = "ec2TerraformTestWebApp"
  }
}


resource "aws_instance" "ec2TerraformTestWebApp2" {
    //aws AMI selection -- Amazon Linux 2
  ami = "ami-099a8245f5daa82bf"

    //aws EC2 instance type, t2.micro for free tier
  instance_type                 = "t2.micro"
  key_name                      = "testkeypair" # You must create this key pairs on your AWS
  subnet_id                     = aws_subnet.TerraformTestPublicSubnet.id
  vpc_security_group_ids        = [aws_security_group.secGroupTerraformTestWebSSH.id]
  //user_data_base64            = "${base64encode(var.userdataEC2)}"
  user_data                     = var.userdataEC2
  iam_instance_profile          =  aws_iam_instance_profile.instanceProfileTerraformTest.name
  tags = {
    Name = "ec2TerraformTestWebApp2"
  }
}


// create DB Subnet Group -- Subnet1+Subnet2
resource "aws_db_subnet_group" "dbSubnetGroupTerraformTest" {
  name       = "dbsubnetgroupterraformtest"
  subnet_ids = [aws_subnet.TerraformTestPublicSubnet.id,aws_subnet.TerraformTestPublicSubnet2.id]

  tags = {
    Name = "dbsubnetgroupterraformtest"
  }
}


resource "aws_db_instance" "rdsTerraformTest" {
  allocated_storage         = 20
  storage_type              = "gp2"
  engine                    = "mysql"
  engine_version            = "5.7"
  instance_class            = "db.t2.micro"
  name                      = "rdsTerraformTest"
  username                  = "alevz"
  password                  = "Passw0rdDB"
  vpc_security_group_ids    = [aws_security_group.secGroupTerraformTestMYSQL.id]
  db_subnet_group_name      = aws_db_subnet_group.dbSubnetGroupTerraformTest.tags.Name
  parameter_group_name      = "default.mysql5.7"
  //backup_retention_period   = 1
  //snapshot_identifier = "some-snap"
  skip_final_snapshot = true
  publicly_accessible = true
  multi_az            = true
}

# resource "aws_db_instance" "rdsTerraformTestReplica" {
#   allocated_storage         = 20
#   storage_type              = "gp2"
#   engine                    = "mysql"
#   engine_version            = "5.7"
#   instance_class            = "db.t2.micro"
#   name                      = "rdsTerraformTestReplica"
#   username                  = "alevz"
#   password                  = "Passw0rdDB"
#   vpc_security_group_ids    = ["${aws_security_group.secGroupTerraformTestMYSQL.id}"]
#   db_subnet_group_name      = "${aws_db_subnet_group.dbSubnetGroupTerraformTest.tags.Name}"
#   parameter_group_name      = "default.mysql5.7"
#   //snapshot_identifier = "some-snap"
#   skip_final_snapshot = true
#   publicly_accessible = true
#   #multi_az            = true
#   replicate_source_db       = "${aws_db_instance.rdsTerraformTest.id}"
# }

output "ip" {
  value = aws_instance.ec2TerraformTestWebApp.public_ip
}

output "ip2" {
  value = aws_instance.ec2TerraformTestWebApp2.public_ip
}

output "ipDB"{
    value = aws_db_instance.rdsTerraformTest.address
}

# output "ipDBReplica"{
#     value = "${aws_db_instance.rdsTerraformTestReplica.address}"
# }

output "dns"{
  value = aws_instance.ec2TerraformTestWebApp.public_dns
}

output "dns2"{
  value = aws_instance.ec2TerraformTestWebApp2.public_dns
}

output "userData"{
    value = var.userdataEC2
}