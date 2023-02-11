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