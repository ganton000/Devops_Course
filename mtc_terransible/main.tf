data "aws_availability_zones" "available" {}

resource "random_id" "random" {
	byte_length = 2
}

resource "aws_vpc" "terraform_vpc" {
	cidr_block = var.vpc_cidr
	enable_dns_hostnames = true
	enable_dns_support = true

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
	route_table_id = aws_route_table.terraform_public_rt.id
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.terraform_internet_gateway.id
}

# only route to vpc (private)
resource "aws_default_route_table" "terraform_private_rt" {
	default_route_table_id = aws_vpc.terraform_vpc.default_route_table_id

	tags = {
		Name = "terraform-private"
	}
}

resource "aws_subnet" "terraform_public_subnet" {
	count = 2 # meta argument
	vpc_id = aws_vpc.terraform_vpc.id
	cidr_block = var.public_cidrs[count.index]
	map_public_ip_on_launch = true # all instances will have public ip
	availability_zone = data.aws_availability_zones.available.names[count.index]

	tags = {
		Name = "terraform-public-${count.index + 1}"
	}
}