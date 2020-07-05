resource "azurerm_network_security_group" "worker" {
  name                = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}-worker"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_network_interface" "worker" {
  count                = var.worker_count
  name                 = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}-${format("${var.worker_name}%d", count.index + 1)}"
  location             = data.azurerm_resource_group.main.location
  resource_group_name  = data.azurerm_resource_group.main.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}-${format("${var.worker_name}%d", count.index + 1)}"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "worker" {
  count                     = var.worker_count
  network_interface_id      = element(azurerm_network_interface.worker.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.worker.id
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}-public-ip"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"

  tags = merge(
    var.default_tags,
    {
      "cluster" = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}"
    },
  )
}

resource "azurerm_lb" "public_load_balancer" {
  name                = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}-public-lb"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}-frontend"
    public_ip_address_id = azurerm_public_ip.public_ip.id
    subnet_id            = data.azurerm_subnet.subnet.id
  }

  tags = merge(
    var.default_tags,
    {
      "cluster" = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}"
    },
  )
}

resource "azurerm_lb_backend_address_pool" "public_address_pool" {
  name                = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}-public-address-pool"
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.public_load_balancer.id
}

resource "azurerm_network_interface_backend_address_pool_association" "worker_public" {
  count                   = var.worker_count
  network_interface_id    = element(azurerm_network_interface.worker.*.id, count.index)
  ip_configuration_name   = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}-${format("${var.worker_name}%d", count.index + 1)}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.public_address_pool.id
}

resource "azurerm_lb" "private_load_balancer" {
  name                = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}-private-lb"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  frontend_ip_configuration {
    name      = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}-frontend"
    subnet_id = data.azurerm_subnet.subnet.id
  }

  tags = merge(
    var.default_tags,
    {
      "cluster" = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}"
    },
  )
}

resource "azurerm_lb_backend_address_pool" "private_address_pool" {
  name                = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}-private-address-pool"
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.public_load_balancer.id
}

resource "azurerm_network_interface_backend_address_pool_association" "worker_private" {
  count                   = var.worker_count
  network_interface_id    = element(azurerm_network_interface.worker.*.id, count.index)
  ip_configuration_name   = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}-${format("${var.worker_name}%d", count.index + 1)}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.private_address_pool.id
}

resource "azurerm_virtual_machine" "worker" {
  count                            = var.worker_count
  name                             = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}-${format("${var.worker_name}%d", count.index + 1)}"
  location                         = data.azurerm_resource_group.main.location
  availability_set_id              = azurerm_availability_set.workers.id
  resource_group_name              = data.azurerm_resource_group.main.name
  network_interface_ids            = [element(azurerm_network_interface.worker.*.id, count.index)]
  vm_size                          = var.worker_vm_size
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = data.azurerm_image.k8s.id
  }

  storage_os_disk {
    name              = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}-${format("${var.worker_name}%d", count.index + 1)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 30
  }

  os_profile {
    computer_name  = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}-${format("${var.worker_name}%d", count.index + 1)}"
    admin_username = "ubuntu"
    admin_password = random_password.vms
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
      "environmentinfo" = "T:Prod; N:${var.cluster_name}-${var.environment}-${random_pet.suffix.id}"
      "cluster"         = "${var.cluster_name}-${var.environment}-${random_pet.suffix.id}"
      "role"            = "worker"
    },
  )
}

