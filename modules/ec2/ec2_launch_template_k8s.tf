# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template

locals {
  public_key = file(var.public_key_path)
}

resource "aws_launch_template" "ec2_instance_launch_template_k8s"{
  block_device_mappings {
    device_name = "/dev/sdb"
    ebs {
      delete_on_termination = true
      volume_size = 20
    }
  }

  name = "ec2_launch_template_k8s"
  description = "EC2 launch template"

  disable_api_stop = false
  disable_api_termination = false

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_profile_k8s.arn
  }

  image_id = var.ami_id
  instance_initiated_shutdown_behavior = "terminate"

  instance_type = var.instance_type

  key_name = aws_key_pair.ec2_instance_key_pair_k8s.key_name

  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "required"
    instance_metadata_tags = "enabled"
  }

  monitoring {
    enabled = true
  }

  private_dns_name_options {
    enable_resource_name_dns_a_record = true
    hostname_type = "ip-name"
  }

#   vpc_security_group_ids = [aws_security_group.instance_security_group.id]

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination = true
    description = "default network interface"
    device_index = 0
#     security_groups = [aws_security_group.instance_security_group_k8s.id]

    # Passing variables from ./main.tf here
    security_groups = var.security_groups
    subnet_id       = var.subnet_id
  }

  update_default_version = true
}

# ----------------------
# IAM role

data "aws_iam_policy_document" "ec2_instance_policy_k8s" {
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

resource "aws_iam_role" "ec2_instance_role_k8s" {
  name               = var.ec2_instance_role_k8s
  path               = var.ec2_role_path
  assume_role_policy = data.aws_iam_policy_document.ec2_instance_policy_k8s.json
}

resource "aws_iam_instance_profile" "ec2_instance_profile_k8s" {
  name = var.ec2_instance_profile_k8s
  role = aws_iam_role.ec2_instance_role_k8s.name
}

# ----------------------
# Key pair

resource "aws_key_pair" "ec2_instance_key_pair_k8s" {
  key_name   = "ec2_instance_key_pair_k8s"
  public_key = local.public_key
}
