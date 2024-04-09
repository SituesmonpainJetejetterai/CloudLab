# Local variables
locals {
  public_subnet_cidr     = element(cidrsubnets(var.aws_vpc_ipam_pool_cidr, 8, 8), 0)
  private_subnet_cidr    = element(cidrsubnets(var.aws_vpc_ipam_pool_cidr, 8, 8), 1)
}

# -----------------
# VPC definition
resource "aws_vpc" "aws_vpc" {
  ipv4_ipam_pool_id   = aws_vpc_ipam_pool.aws_vpc_ipam_pool.id
  ipv4_netmask_length = element(split("/", var.aws_vpc_ipam_pool_cidr), 1)
  depends_on = [
    aws_vpc_ipam_pool_cidr.aws_vpc_ipam_pool_cidr
  ]

  enable_dns_support                   = "true"
  enable_dns_hostnames                 = "true"
  enable_network_address_usage_metrics = "true"

  tags = {
    Name        = "cloud_project"
    Environment = "aws_vpc"
  }
}

# -----------------
# IPAM configuration

data "aws_region" "current_region" {}

resource "aws_vpc_ipam" "aws_vpc_ipam" {
  operating_regions {
    region_name = data.aws_region.current_region.name
  }
}

resource "aws_vpc_ipam_pool" "aws_vpc_ipam_pool" {
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam.aws_vpc_ipam.private_default_scope_id
  locale         = data.aws_region.current_region.name
}

resource "aws_vpc_ipam_pool_cidr" "aws_vpc_ipam_pool_cidr" {
  ipam_pool_id = aws_vpc_ipam_pool.aws_vpc_ipam_pool.id
  cidr         = var.aws_vpc_ipam_pool_cidr
}

# -----------------
# Subnet configuration

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.aws_vpc.id
  cidr_block = local.public_subnet_cidr
  #   cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.aws_vpc.id
  cidr_block = local.private_subnet_cidr
  #   cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Private Subnet"
  }
}

# -----------------
# Internet Gateway configuration

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.aws_vpc.id

  tags = {
    Name = "IGW"
  }
}

# -----------------
# Routing table configuration

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.aws_vpc.id

  route {
    #     cidr_block = var.aws_vpc_ipam_pool_cidr
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Route Table"
  }
}

resource "aws_route_table_association" "aws_route_table_association_subnet" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.route_table.id
}

# -----------------
# Security group configuration

resource "aws_security_group" "instance_security_group_k8s" {
  name        = "instance_security_group_k8s"
  description = "SSH"
  vpc_id      = aws_vpc.aws_vpc.id

  tags = {
    Name = "instance_security_group"
  }
}

# SSH rules

resource "aws_vpc_security_group_ingress_rule" "instance_security_group_ingress_ssh_ipv4" {
  security_group_id = aws_security_group.instance_security_group_k8s.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.ssh_from_port
  ip_protocol       = "tcp"
  to_port           = var.ssh_to_port
}

resource "aws_vpc_security_group_ingress_rule" "instance_security_group_ingress_ssh_ipv6" {
  security_group_id = aws_security_group.instance_security_group_k8s.id
  cidr_ipv6         = "::/0"
  from_port         = var.ssh_from_port
  ip_protocol       = "tcp"
  to_port           = var.ssh_to_port
}

# Egress rules

resource "aws_vpc_security_group_egress_rule" "instance_security_group_egress_all_ipv4" {
  security_group_id = aws_security_group.instance_security_group_k8s.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "instance_security_group_egress_all_ipv6" {
  security_group_id = aws_security_group.instance_security_group_k8s.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}

# ---------------------
# Outputs

output "ec2_instance_security_group_k8s" {
  value = [aws_security_group.instance_security_group_k8s.id]
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "public_subnet_cidr" {
  value = local.public_subnet_cidr
}

output "private_subnet_cidr" {
  value = local.private_subnet_cidr
}
