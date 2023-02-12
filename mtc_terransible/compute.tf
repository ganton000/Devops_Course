data "aws_ami" "server_ami" {
	most_recent = true

	owners = ["099720109477"]

	filter {
		name = "name"
		values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
	}
}

resource "aws_instance" "terraform_main" {
	instance_type = var.main_instance_type #t2.micro
	ami = data.aws_ami.server_ami.id
	# key_name
	vpc_security_group_ids = [ aws_security_group.terraform_sg.id ]
	subnet_id = aws_subnet.terraform_public_subnet[0].id

	root_block_device {
	volume_size = var.main_vol_size # 8 gibibytes (GiB)

	tags = {
		Name = "terraform-main"
	}
	}
}