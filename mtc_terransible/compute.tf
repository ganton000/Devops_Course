locals {
	subnet_count = length(aws_subnet.terraform_public_subnet)
}

resource "random_id" "ec2_random_id" {
	byte_length = 2
	count = var.ec2_instance_count
}

resource "aws_key_pair" "terraform_auth" {
	key_name = var.key_name
	public_key = file(var.public_key_path)
}

data "aws_ami" "server_ami" {
	most_recent = true

	owners = ["099720109477"]

	filter {
		name = "name"
		values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
	}
}

resource "aws_instance" "terraform_main" {
	count = var.ec2_instance_count
	instance_type = var.main_instance_type #t2.micro
	ami = data.aws_ami.server_ami.id
	# key_name
	vpc_security_group_ids = [ aws_security_group.terraform_sg.id ]
	subnet_id = aws_subnet.terraform_public_subnet[count.index].id

	root_block_device {
		volume_size = var.main_vol_size # 8 gibibytes (GiB)
	}

	tags = {
		Name = "terraform-main-${random_id.ec2_random_id[count.index].dec}"
	}
}
