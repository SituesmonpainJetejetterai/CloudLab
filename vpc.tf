# Local variables
locals {
  aws_vpc_ipam_pool_cidr = "10.1.0.0/16"
  public_subnet_cidr     = element(cidrsubnets(local.aws_vpc_ipam_pool_cidr, 8, 8), 0)
  private_subnet_cidr    = element(cidrsubnets(local.aws_vpc_ipam_pool_cidr, 8, 8), 1)

  ssh_from_port = "22"
  ssh_to_port   = "22"

  https_from_port = "443"
  https_to_port   = "443"

  dns_from_port = "53"
  dns_to_port   = "53"
}

# -----------------
# VPC definition
resource "aws_vpc" "aws_vpc" {
  ipv4_ipam_pool_id   = aws_vpc_ipam_pool.aws_vpc_ipam_pool.id
  ipv4_netmask_length = element(split("/", local.aws_vpc_ipam_pool_cidr), 1)
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
  cidr         = local.aws_vpc_ipam_pool_cidr
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
    #     cidr_block = local.aws_vpc_ipam_pool_cidr
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

# resource "aws_route_table_association" "aws_route_table_association_gateway" {
#   gateway_id     = aws_internet_gateway.igw.id
#   route_table_id = aws_route_table.route_table.id
# }

# -----------------
# Security group configuration

resource "aws_security_group" "instance_security_group" {
  name        = "instance_security_group"
  description = "Saltstack, HTTPS, k8s, SSH"
  vpc_id      = aws_vpc.aws_vpc.id

  tags = {
    Name = "instance_security_group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "instance_security_group_ingress_ssh_ipv4" {
  security_group_id = aws_security_group.instance_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = local.ssh_from_port
  ip_protocol       = "tcp"
  to_port           = local.ssh_to_port
}


resource "aws_vpc_security_group_egress_rule" "instance_security_group_egress_ssh_ipv4" {
  security_group_id = aws_security_group.instance_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = local.ssh_from_port
  ip_protocol       = "tcp"
  to_port           = local.ssh_to_port
}

resource "aws_vpc_security_group_ingress_rule" "instance_security_group_ingress_ssh_ipv6" {
  security_group_id = aws_security_group.instance_security_group.id
  cidr_ipv6         = "::/0"
  from_port         = local.ssh_from_port
  ip_protocol       = "tcp"
  to_port           = local.ssh_to_port
}

resource "aws_vpc_security_group_egress_rule" "instance_security_group_egress_ssh_ipv6" {
  security_group_id = aws_security_group.instance_security_group.id
  cidr_ipv6         = "::/0"
  from_port         = local.ssh_from_port
  ip_protocol       = "tcp"
  to_port           = local.ssh_to_port
}

# -----------------

resource "aws_vpc_security_group_egress_rule" "instance_security_group_egress_https_ipv4" {
  security_group_id = aws_security_group.instance_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = local.https_from_port
  ip_protocol       = "tcp"
  to_port           = local.https_to_port
}

resource "aws_vpc_security_group_egress_rule" "instance_security_group_egress_https_ipv6" {
  security_group_id = aws_security_group.instance_security_group.id
  cidr_ipv6         = "::/0"
  from_port         = local.https_from_port
  ip_protocol       = "tcp"
  to_port           = local.https_to_port
}

# -----------------

resource "aws_vpc_security_group_egress_rule" "instance_security_group_egress_dns_ipv4" {
  security_group_id = aws_security_group.instance_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = local.dns_from_port
  ip_protocol       = "udp"
  to_port           = local.dns_to_port
}

resource "aws_vpc_security_group_egress_rule" "instance_security_group_egress_dns_ipv6" {
  security_group_id = aws_security_group.instance_security_group.id
  cidr_ipv6         = "::/0"
  from_port         = local.dns_from_port
  ip_protocol       = "udp"
  to_port           = local.dns_to_port
}
