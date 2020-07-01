variable "cluster_name" {
  type    = string
  default = "k8s"
}

variable "environment" {
  type    = string
  default = "labs"
}

variable "main_resource_group" {
  type    = string
  default = "resource_group_default"
}

variable "images_resource_group" {
  type    = string
  default = "resource_group_default"
}

variable "vnet_name" {
  type    = string
  default = "vnet_default"
}

variable "subnet_name" {
  type    = string
  default = "default_subnet"
}

variable "k8s_image_name" {
  type    = string
  default = "k8s"
}

variable "bastion_image_name" {
  type    = string
  default = "bastion"
}

variable "ssh_public_key" {
  type = string
}

variable "default_tags" {
  type = map(string)

  default = {
    applicationname = "k8s"
    deploymenttype  = "Terraform"
    platform        = "Kubernetes"
  }
}

variable "worker_count" {
  type    = string
  default = "3"
}

variable "worker_name" {
  type    = string
  default = "worker"
}

variable "manager_count" {
  type    = string
  default = "3"
}

variable "worker_vm_size" {
  type    = string
  default = "Standard_DS4_v2"
}

variable "manager_vm_size" {
  type    = string
  default = "Standard_DS2_v2"
}

variable "add_managers" {
  type    = string
  default = "yes"
}

variable "add_bastion" {
  type    = string
  default = "yes"
}

variable "block_bastion_ssh" {
  type    = string
  default = "yes"
}

variable "bastion_ssh_allowed_ips" {
  type    = list(string)
  default = []
}

variable "add_manager_lb" {
  type    = string
  default = "no"
}
