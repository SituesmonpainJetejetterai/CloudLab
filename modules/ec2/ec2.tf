# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
# To-do:
# Customise for free EC2 instance
# Set up cloud-init directives to set up a user, download necessary packages (git, vim, salt etc) and other pre-orchestration tooling

resource "aws_instance" "ec2_instance_k8s_master" {
  count = 1
  launch_template {
    id      = aws_launch_template.ec2_instance_launch_template_k8s_master.id
    version = "$Latest"
  }

  user_data = templatefile("${path.module}/scripts/k8s.sh", {node_name="controlplane", count="${count.index}"})
  user_data_replace_on_change = true

  tags = {
    Name = "k8s-master-${count.index}"
  }
}

resource "aws_instance" "ec2_instance_k8s_worker" {
  count = 2
  launch_template {
    id      = aws_launch_template.ec2_instance_launch_template_k8s_worker.id
    version = "$Latest"
  }

  user_data = templatefile("${path.module}/scripts/k8s.sh", {node_name="worker", count="${count.index}"})
  user_data_replace_on_change = true

  tags = {
    Name = "k8s-worker-${count.index}"
  }
}

# ---------------------
# Output public DNS of EC2
# https://developer.hashicorp.com/terraform/language/meta-arguments/count#referring-to-instances

output "ec2_instance_public_dns_master" {
  value = aws_instance.ec2_instance_k8s_master[*].public_dns
}

output "ec2_instance_public_dns_worker" {
  value = aws_instance.ec2_instance_k8s_worker[*].public_dns
}
