## local variables/params
locals {
  azs = data.aws_availability_zones.available.names
}

## data source
data "aws_availability_zones" "available" {}

resource "random_id" "random" {
  byte_length = 2
}

resource "aws_vpc" "terraform_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "terraform_vpc-${random_id.random.dec}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_internet_gateway" "terraform_internet_gateway" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "terraform_igw-${random_id.random.dec}"
  }
}

resource "aws_route_table" "terraform_public_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "terraform-public"
  }
}

resource "aws_route" "terraform_route" {
  route_table_id         = aws_route_table.terraform_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.terraform_internet_gateway.id
}

# only route to vpc (private)
resource "aws_default_route_table" "terraform_private_rt" {
  default_route_table_id = aws_vpc.terraform_vpc.default_route_table_id

  tags = {
    Name = "terraform-private"
  }
}

resource "aws_subnet" "terraform_public_subnet" {
  count                   = length(local.azs) # meta argument with length function
  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true # all instances will have public ip
  availability_zone       = local.azs[count.index]

  tags = {
    Name = "terraform-public-${count.index + 1}"
  }
}

resource "aws_subnet" "terraform_private_subnet" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, length(local.azs) + count.index)
  map_public_ip_on_launch = false
  availability_zone       = local.azs[count.index]

  tags = {
    Name = "terraform-private-${count.index + 1}"
  }

}

## associate subnets to route table
resource "aws_route_table_association" "terrform_public_rt_assoc" {
  count          = length(local.azs)
  subnet_id      = aws_subnet.terraform_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.terraform_public_rt.id
}

## private subnets default to the default route table
## so no need to associate
## associate subnets to route table
#resource "aws_route_table_association" "terrform_private_rt_assoc" {
#	count = length(local.azs)
#	subnet_id = aws_subnet.terraform_private_subnet[count.index].id
#	route_table_id = aws_default_route_table.terraform_private_rt.id
#}

resource "aws_security_group" "terraform_sg" {
  name        = "public_sg"
  description = "security group for public instances"
  vpc_id      = aws_vpc.terraform_vpc.id
}

resource "aws_security_group_rule" "ingress_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1" # any protocol [TCP,UDP,ICMP]
  cidr_blocks       = [var.access_ip]
  security_group_id = aws_security_group.terraform_sg.id
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1" # any protocol [TCP,UDP,ICMP]
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.terraform_sg.id
}

#resource "aws_security_group" "terraform_sg" {
#	name = "private_sg"
#	description = "security group for private instances"
#}
