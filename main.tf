# Dependency inversion is the cornerstone of being able to write Terraform modules
# 1. Create outputs for variables that would need to be passed to the other module(s)
# 2. Assign variables in the local variables.tf of said module, and provide default values for variables in the root main.tf
# 3. Utilise the structure "module.<output_module_name>.variable" to pass variables to the latter module
# https://developer.hashicorp.com/terraform/language/modules/develop/composition#dependency-inversion

module "ec2" {
  source = "./modules/ec2"

  security_groups_master = module.vpc.ec2_instance_security_group_k8s_master
  security_groups_worker = module.vpc.ec2_instance_security_group_k8s_worker
  subnet_id              = module.vpc.public_subnet_id
  public_subnet_cidr     = module.vpc.public_subnet_cidr
  private_subnet_cidr    = module.vpc.private_subnet_cidr

  ec2_instance_profile_k8s_master = "ec2_instance_profile_k8s_master"
  ec2_instance_role_k8s_master    = "ec2_instance_role_k8s_master"

  ec2_instance_profile_k8s_worker = "ec2_instance_profile_k8s_worker"
  ec2_instance_role_k8s_worker    = "ec2_instance_role_k8s_worker"

  #   ec2_instance_profile_saltstack = "ec2_instance_profile_saltstack"
  #   ec2_instance_role_saltstack    = "ec2_instance_role_saltstack"

  ec2_role_path = "/cloud_project/"

  # ami_id          = "ami-0fe630eb857a6ec83"  # Alma Linux 9 AMI
  ami_id = "ami-0f936eaf4f00cc550" # RHEL 9 AMI
  # instance_type   = "t2.micro"
  instance_type   = "t2.medium"
  public_key_path = "~/.ssh/ec2_instance_key.pub"
}

module "vpc" {
  source = "./modules/vpc"

  aws_vpc_ipam_pool_cidr = "10.1.0.0/16"
  ssh_from_port          = "22"
  ssh_to_port            = "22"
  https_from_port        = "443"
  https_to_port          = "443"
  dns_from_port          = "53"
  dns_to_port            = "53"
  #   saltstack_from_port    = "4505"
  #   saltstack_to_port      = "4506"
}

# ----------------------
output "ec2_instances_public_dns" {
  value = module.ec2
}
