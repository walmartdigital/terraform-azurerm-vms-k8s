resource "azurerm_network_security_group" "manager" {
  name                = "${local.full_name}-manager"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags = merge(
    var.default_tags,
    {
      "cluster" = local.full_name
    },
  )
}

resource "azurerm_network_interface" "manager" {
  count               = var.manager_count
  name                = "${local.full_name}-manager-${count.index + 1}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${local.full_name}-manager-${count.index + 1}"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
  }

  tags = merge(
    var.default_tags,
    {
      "cluster" = local.full_name
      "role"    = "manager"
    },
  )
}

resource "azurerm_network_interface_security_group_association" "manager" {
  count                     = var.manager_count
  network_interface_id      = element(azurerm_network_interface.manager.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.manager.id
}

resource "azurerm_availability_set" "managers" {
  name                        = "${local.full_name}-managers"
  location                    = data.azurerm_resource_group.main.location
  resource_group_name         = data.azurerm_resource_group.main.name
  managed                     = true
  platform_fault_domain_count = 2
  tags = merge(
    var.default_tags,
    {
      "cluster" = local.full_name
      "role"    = "manager"
    },
  )
}

resource "azurerm_virtual_machine" "manager" {
  count                            = var.manager_count
  name                             = "${local.full_name}-manager-${count.index + 1}"
  location                         = data.azurerm_resource_group.main.location
  availability_set_id              = azurerm_availability_set.managers.id
  resource_group_name              = data.azurerm_resource_group.main.name
  network_interface_ids            = [element(azurerm_network_interface.manager.*.id, count.index)]
  vm_size                          = var.manager_vm_size
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = data.azurerm_image.k8s.id
  }

  storage_os_disk {
    name              = "${local.full_name}-manager-${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.full_name}-manager-${count.index + 1}"
    admin_username = "ubuntu"
    admin_password = random_password.vms.result
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/ubuntu/.ssh/authorized_keys"
      key_data = var.ssh_public_key
    }
  }

  tags = merge(
    var.default_tags,
    {
      "cluster" = local.full_name
      "role"    = "manager"
    },
  )
}
