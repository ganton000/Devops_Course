resource "aws_vpc" "terraform_vpc" {
	cidr_block = var.vpc_cidr
	enable_dns_hostnames = true
	enable_dns_support = true

	tags = {
		Name = "terraform_vpc"
	}
}