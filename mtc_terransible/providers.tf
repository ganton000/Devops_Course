terraform {
  required_providers {
	aws = {
		source = "hashicorp/aws"
	}
  }
}

provider "aws" {
	profile = "admin"
	region = "us-east-1"
}

