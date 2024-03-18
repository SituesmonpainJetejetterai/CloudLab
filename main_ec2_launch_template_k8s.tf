# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template

locals {
  public_key = file(var.public_key_path)
}

resource "aws_launch_template" "ec2_instance_launch_template"{
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
    arn = aws_iam_instance_profile.ec2_instance_profile.arn
  }

  image_id = var.ami_id
  instance_initiated_shutdown_behavior = "terminate"

  instance_type = var.instance_type

  key_name = aws_key_pair.ec2_instance_key_pair.key_name

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
    security_groups = [aws_security_group.instance_security_group_k8s.id]
    subnet_id = aws_subnet.public_subnet.id
  }

  update_default_version = true
}

# ----------------------
# IAM role

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

# ----------------------
# Key pair

resource "aws_key_pair" "ec2_instance_key_pair" {
  key_name   = "ec2_instance_key_pair"
  public_key = local.public_key
}
