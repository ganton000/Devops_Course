locals {
  subnet_count = length(aws_subnet.terraform_public_subnet)
}

resource "random_id" "ec2_random_id" {
  byte_length = 2
  count       = var.ec2_instance_count
}

resource "aws_key_pair" "terraform_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

data "aws_ami" "server_ami" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "terraform_main" {
  count                  = var.ec2_instance_count
  instance_type          = var.main_instance_type #t2.micro
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.terraform_auth.id #can also use .key_name
  vpc_security_group_ids = [aws_security_group.terraform_sg.id]
  subnet_id              = aws_subnet.terraform_public_subnet[count.index].id
  #user_data = templatefile("./main-userdata.tpl", {
  #  new_hostname = "terraform-main-${random_id.ec2_random_id[count.index].dec}"
  #})

  root_block_device {
    volume_size = var.main_vol_size # 8 gibibytes (GiB)
  }

  tags = {
    Name = "terraform-main-${random_id.ec2_random_id[count.index].dec}"
  }

  # runs every time this resource is created
  ## provisioners have hyphens
  ## self keyword within provisioner references the resource it is in
  ## can specifiy interpreter as well
  #provisioner "local-exec" {
  #  command = "printf \"\n${self.public_ip}\" >> aws_hosts && aws ec2 wait instance-status-ok --instance-ids {self.id} --region us-east-1 --profile admin"
  #}

  ### destroy provisioner -- acts as cleanup
  ### only works when terraform destroy command is run
  #provisioner "local-exec" {
  #  when    = destroy
  #  command = "sed -i -e '/^[0-9]/d' aws_hosts"
  #}
}

## remote provisioner --
# modifies resource after deployed
# since it modifies our above aws_instance (ec2 instance resource), then
# must be created outside of that resource block
# null_resource is a placeholder for an empty resource
#resource "null_resource" "grafana_update" {

#  count = var.ec2_instance_count
#  provisioner "remote-exec" {

#    inline = ["sudo apt upgrade -y grafana && touch upgrade.log && echo 'I updated Grafana' >> upgrade.log"]

#    connection {
#      type        = "ssh"
#      user        = "ubuntu"
#      private_key = file("~/.ssh/terrakey")
#      host        = aws_instance.terraform_main[count.index].public_ip
#    }
#  }
#}

## use ansible playbook instead of user_data for instances
resource "null_resource" "grafana_install" {
  depends_on = [aws_instance.terraform_main] # instances need to exist for

  provisioner "local-exec" {
    # -i specifies custom inventory file
    #
    command = "ansible-playbook -i aws_hosts --key-file ~/.ssh/terrakey playbooks/grafana.yml"

  }
}

output "instance_ips" {
  value = [for i in aws_instance.mtc_main[*]: i.public_ip ]
}

#terraform output will show the output above
