module "ec2" {
  source          = "./modules/ec2"
  security_groups = module.vpc.ec2_instance_security_group_k8s
  subnet_id       = module.vpc.public_subnet_id

  ec2_instance_profile_k8s = "ec2_instance_profile_k8s"
  ec2_instance_role_k8s    = "ec2_instance_role_k8s"

  ec2_role_path = "/cloud_project/"

  ami_id          = "ami-0fe630eb857a6ec83"
  instance_type   = "t2.micro"
  public_key_path = "~/.ssh/ec2_instance_key.pub"

  ec2_instance_profile_saltstack = "ec2_instance_profile_saltstack"
  ec2_instance_role_saltstack    = "ec2_instance_role_saltstack"
}

module "vpc" {
  source = "./modules/vpc"
}

# ----------------------
output "ec2_instances_public_dns" {
  value = module.ec2
}
