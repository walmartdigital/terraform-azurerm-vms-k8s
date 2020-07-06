# Kubernetes Virtual Machines Module

This module create all required resources for deploy a kubernetes cluster using
RKE (Rancher Kubernetes Engine).

## Usage

```bash
module "az_vms" {
  source                             = "walmartdigital/vms-k8s/azurerm"
  version                            = "1.0.0"
  add_bastion                        = true
  bastion_image_name                 = "bastion-v1.0.0"
  bastion_ssh_allowed_ips            = []
  cluster_name                       = "my-k8s"
  default_tags                       = {
    platform = "Kubernetes"
  }
  environment                        = "labs"
  images_resource_group              = "resource_group_default"
  k8s_image_name                     = "k8s-v1.0.0"
  lb_ports                           = [{
    name         = "http"
    port         = "80"
    protocol     = "Tcp"
    backend_port = 30000
    probe_port   = 30000
    probe_path   = "/"
    target       = "workers"
    visibility   = "public"
  }, {
    name         = "http"
    port         = "80"
    protocol     = "Tcp"
    backend_port = 30000
    probe_port   = 30000
    probe_path   = "/"
    target       = "workers"
    visibility   = "private"
  }]
  main_resource_group                = "resource_group_default"
  manager_vm_size                    = "Standard_DS2_v2"
  ssh_public_key                     = "abc123"
  subnet_name                        = "my-subnet-name"
  vnet_name                          = "my-vnet-name"
  bastion_image_name                 = "bastion-v1.0.0"
  worker_count                       = 3
  worker_vm_size                     = "Standard_DS4_v2"
}
```

By default all ssh access to to Bastion is blocked. If its needed allow access
trough internet, must be used a white list of allowed ips:

```yaml
bastion_ssh_allowed_ips                 = ["10.0.0.1", "AzureCloud"]
```

Take on consideration that can be used Azure wildcards like **AzureCloud**
(allow access to any azure public cloud).

## Outputs

- **bastion_public_ip**: The bastion public IP address.
- **bastion_private_ip**: The bastion private IP address.
- **worker_ips**: The private IPs of the created worker VMs.
- **manager_ips**: The private IPs of the created manager VMs.
