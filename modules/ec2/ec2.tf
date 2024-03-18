# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
# To-do:
# Customise for free EC2 instance
# Set up cloud-init directives to set up a user, download necessary packages (git, vim, salt etc) and other pre-orchestration tooling

resource "aws_instance" "ec2_instance_master" {
  count = 3
  launch_template {
    id      = aws_launch_template.ec2_instance_launch_template_k8s.id
    version = "$Latest"
  }
  tags = {
    Name = "k8s-master-${count.index}"
  }
}

resource "aws_instance" "ec2_instance_worker" {
  count = 2
  launch_template {
    id      = aws_launch_template.ec2_instance_launch_template_k8s.id
    version = "$Latest"
  }
  tags = {
    Name = "k8s-worker-${count.index}"
  }
}

resource "aws_instance" "ec2_instance_saltstack_master" {
  launch_template {
    id      = aws_launch_template.ec2_instance_launch_template_saltstack_master.id
    version = "$Latest"
  }

  tags = {
    Name = "saltstack-master"
  }
}

# ---------------------
# Output public DNS of EC2
# https://developer.hashicorp.com/terraform/language/meta-arguments/count#referring-to-instances

output "ec2_instance_public_dns_saltstack_master" {
  value = aws_instance.ec2_instance_saltstack_master.public_dns
}
output "ec2_instance_public_dns_master" {
  value = aws_instance.ec2_instance_master[*].public_dns
}

output "ec2_instance_public_dns_worker" {
  value = aws_instance.ec2_instance_worker[*].public_dns
}
