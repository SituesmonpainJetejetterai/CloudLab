variable "ec2_instance_profile" {
  type = string
}
variable "ec2_instance_role" {
  type = string
}
variable "ec2_role_path" {
  type = string
}
variable "public_key_path" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}


# -----------------

variable "ec2_instance_profile_saltstack" {
  type = string
}
variable "ec2_instance_role_saltstack" {
  type = string
}
variable "ec2_role_path_saltstack" {
  type = string
}
