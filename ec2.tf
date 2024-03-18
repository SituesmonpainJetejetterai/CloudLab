# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
# To-do:
# Customise for free EC2 instance
# Set up cloud-init directives to set up a user, download necessary packages (git, vim, salt etc) and other pre-orchestration tooling

locals {
  public_key = file(var.public_key_path)
}

resource "aws_instance" "ec2_instance" {
  ami           = "ami-0fe630eb857a6ec83"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id

  associate_public_ip_address = true
  disable_api_stop            = false
  disable_api_termination     = false

  key_name = aws_key_pair.ec2_instance_key_pair.key_name

  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "required"
    instance_metadata_tags = "enabled"
  }

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  vpc_security_group_ids = [aws_security_group.instance_security_group.id]
}

resource "aws_key_pair" "ec2_instance_key_pair" {
  key_name   = "ec2_instance_key_pair"
  public_key = local.public_key
}
# ---------------------
# Network interface and attachment
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface_attachment

# resource "aws_network_interface" "ec2_network_interface" {
#   subnet_id       = aws_subnet.public_subnet.id
#   security_groups = [aws_security_group.instance_security_group.id]
# }
# 
# resource "aws_network_interface_attachment" "ec2_network_interface_attachment" {
#   instance_id          = aws_instance.ec2_instance.id
#   network_interface_id = aws_network_interface.ec2_network_interface.id
#   device_index         = 1
# }

# ---------------------
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile

data "aws_iam_policy_document" "ec2_instance_policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2_instance_role" {
  name               = var.ec2_instance_role
  path               = var.ec2_role_path
  assume_role_policy = data.aws_iam_policy_document.ec2_instance_policy.json
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = var.ec2_instance_profile
  role = aws_iam_role.ec2_instance_role.name
}

# ---------------------
# Output public DNS of EC2

output "ec2_instance_public_dns" {
  value = aws_instance.ec2_instance.public_dns
}
