terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  features {}
}

locals {
  full_name = var.cluster_name != "" ? "${var.cluster_name}-${random_pet.suffix.id}" : random_pet.suffix.id
}

resource "random_pet" "suffix" {
}

resource "random_password" "vms" {
  length           = 16
  special          = true
  override_special = "_%@"
}

data "azurerm_resource_group" "main" {
  name = var.main_resource_group
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = data.azurerm_resource_group.main.name
}

data "azurerm_image" "k8s" {
  name                = var.k8s_image_name
  resource_group_name = var.images_resource_group
}

data "azurerm_image" "bastion" {
  name                = var.bastion_image_name
  resource_group_name = var.images_resource_group
}
