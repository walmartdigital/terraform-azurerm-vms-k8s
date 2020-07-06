variable "add_bastion" {
  type    = bool
  default = true
}

variable "bastion_image_name" {
  type    = string
  default = "bastion-v1.0.0"
}

variable "bastion_ssh_allowed_ips" {
  type    = list(string)
  default = []
}

variable "cluster_name" {
  type    = string
  default = "k8s"
}

variable "default_tags" {
  type = map(string)

  default = {
    platform = "Kubernetes"
  }
}

variable "environment" {
  type    = string
  default = "labs"
}

variable "images_resource_group" {
  type    = string
  default = "resource_group_default"
}

variable "k8s_image_name" {
  type    = string
  default = "k8s-v1.0.0"
}

variable "lb_ports" {
  type = list
  default = [{
    name         = "http"
    port         = "80"
    protocol     = "Tcp"
    backend_port = 30000
    probe_port   = 30000
    probe_path   = "/"
    target       = "workers"
    visibility   = "public"
  }]
}

variable "main_resource_group" {
  type    = string
  default = "resource_group_default"
}

variable "manager_count" {
  type    = string
  default = "3"
}

variable "manager_vm_size" {
  type    = string
  default = "Standard_DS2_v2"
}

variable "ssh_public_key" {
  type = string
}

variable "subnet_name" {
  type    = string
  default = "default_subnet"
}

variable "vnet_name" {
  type    = string
  default = "vnet_default"
}

variable "worker_count" {
  type    = string
  default = "3"
}

variable "worker_vm_size" {
  type    = string
  default = "Standard_DS4_v2"
}

