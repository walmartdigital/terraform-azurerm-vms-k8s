resource "azurerm_network_security_group" "worker" {
  name                = "${var.cluster_name}-${random_pet.suffix.id}-worker"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_network_security_rule" "k8s_services" {
  name                        = "k8s-services"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "30000-30010"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.worker.name
}

resource "azurerm_network_interface" "worker" {
  count                = var.worker_count
  name                 = "${var.cluster_name}-${random_pet.suffix.id}-worker-${count.index + 1}"
  location             = data.azurerm_resource_group.main.location
  resource_group_name  = data.azurerm_resource_group.main.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${var.cluster_name}-${random_pet.suffix.id}-worker-${count.index + 1}"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "worker" {
  count                     = var.worker_count
  network_interface_id      = element(azurerm_network_interface.worker.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.worker.id
}

locals {
  lb_ports_public = [for v in var.lb_ports : v if v.visibility == "public"]
}

resource "azurerm_public_ip" "public_ip" {
  count               = length(local.lb_ports_public) > 0 ? 1 : 0
  name                = "${var.cluster_name}-${random_pet.suffix.id}-public-ip"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"

  tags = merge(
    var.default_tags,
    {
      "cluster" = "${var.cluster_name}-${random_pet.suffix.id}"
    },
  )
}

resource "azurerm_lb" "load_balancer_public" {
  count               = length(local.lb_ports_public) > 0 ? 1 : 0
  name                = "${var.cluster_name}-${random_pet.suffix.id}-public-lb"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "${var.cluster_name}-${random_pet.suffix.id}-frontend-public"
    public_ip_address_id = azurerm_public_ip.public_ip[0].id
    subnet_id            = data.azurerm_subnet.subnet.id
  }

  tags = merge(
    var.default_tags,
    {
      "cluster" = "${var.cluster_name}-${random_pet.suffix.id}"
    },
  )
}

resource "azurerm_lb_probe" "lb_probe_public" {
  count               = length(local.lb_ports_public)
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.load_balancer_public[0].id
  name                = local.lb_ports_public[count.index].name
  protocol            = local.lb_ports_public[count.index].probe_path != "" ? "http" : "Tcp"
  port                = local.lb_ports_public[count.index].probe_port
  interval_in_seconds = local.lb_ports_public[count.index].probe_interval
  number_of_probes    = local.lb_ports_public[count.index].probe_threshold
  request_path        = local.lb_ports_public[count.index].probe_path != "" ? local.lb_ports_public[count.index].probe_path : ""
}

resource "azurerm_lb_rule" "lb_rule_public" {
  count                          = length(local.lb_ports_public)
  resource_group_name            = data.azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.load_balancer_public[0].id
  name                           = local.lb_ports_public[count.index].name
  protocol                       = local.lb_ports_public[count.index].protocol
  frontend_port                  = local.lb_ports_public[count.index].port
  backend_port                   = local.lb_ports_public[count.index].backend_port
  frontend_ip_configuration_name = "${var.cluster_name}-${random_pet.suffix.id}-frontend-public"
  enable_floating_ip             = false
  backend_address_pool_id        = azurerm_lb_backend_address_pool.address_pool_public.id
  idle_timeout_in_minutes        = 5
  probe_id                       = element(concat(azurerm_lb_probe.lb_probe_public.*.id, list("")), count.index)
  depends_on                     = [azurerm_public_ip.public_ip[0], azurerm_lb_probe.lb_probe_public]
}

resource "azurerm_lb_backend_address_pool" "address_pool_public" {
  name                = "${var.cluster_name}-${random_pet.suffix.id}-address-pool-public"
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.load_balancer_public[0].id
}

resource "azurerm_network_interface_backend_address_pool_association" "worker_public" {
  count                   = var.worker_count
  network_interface_id    = element(azurerm_network_interface.worker.*.id, count.index)
  ip_configuration_name   = "${var.cluster_name}-${random_pet.suffix.id}-worker-${count.index + 1}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.address_pool_public.id
}

locals {
  lb_ports_private = [for v in var.lb_ports : v if v.visibility == "private"]
}

resource "azurerm_lb" "load_balancer_private" {
  count               = length(local.lb_ports_private) > 0 ? 1 : 0
  name                = "${var.cluster_name}-${random_pet.suffix.id}-private-lb"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  frontend_ip_configuration {
    name      = "${var.cluster_name}-${random_pet.suffix.id}-frontend-private"
    subnet_id = data.azurerm_subnet.subnet.id
  }

  tags = merge(
    var.default_tags,
    {
      "cluster" = "${var.cluster_name}-${random_pet.suffix.id}"
    },
  )
}

resource "azurerm_lb_probe" "lb_probe_private" {
  count               = length(local.lb_ports_private)
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.load_balancer_private[0].id
  name                = local.lb_ports_private[count.index].name
  protocol            = local.lb_ports_private[count.index].probe_path != "" ? "http" : "Tcp"
  port                = local.lb_ports_private[count.index].probe_port
  interval_in_seconds = local.lb_ports_private[count.index].probe_interval
  number_of_probes    = local.lb_ports_private[count.index].probe_threshold
  request_path        = local.lb_ports_private[count.index].probe_path != "" ? local.lb_ports_private[count.index].probe_path : ""
}

resource "azurerm_lb_rule" "lb_rule_private" {
  count                          = length(local.lb_ports_private)
  resource_group_name            = data.azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.load_balancer_private[0].id
  name                           = local.lb_ports_private[count.index].name
  protocol                       = local.lb_ports_private[count.index].protocol
  frontend_port                  = local.lb_ports_private[count.index].port
  backend_port                   = local.lb_ports_private[count.index].backend_port
  frontend_ip_configuration_name = "${var.cluster_name}-${random_pet.suffix.id}-frontend-private"
  enable_floating_ip             = false
  backend_address_pool_id        = azurerm_lb_backend_address_pool.address_pool_private.id
  idle_timeout_in_minutes        = 5
  probe_id                       = element(concat(azurerm_lb_probe.lb_probe_private.*.id, list("")), count.index)
  depends_on                     = [azurerm_lb_probe.lb_probe_private]
}

resource "azurerm_lb_backend_address_pool" "address_pool_private" {
  name                = "${var.cluster_name}-${random_pet.suffix.id}-private-address-pool"
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.load_balancer_public[0].id
}

resource "azurerm_network_interface_backend_address_pool_association" "worker_private" {
  count                   = var.worker_count
  network_interface_id    = element(azurerm_network_interface.worker.*.id, count.index)
  ip_configuration_name   = "${var.cluster_name}-${random_pet.suffix.id}-worker-${count.index + 1}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.address_pool_private.id
}

resource "azurerm_virtual_machine" "worker" {
  count                            = var.worker_count
  name                             = "${var.cluster_name}-${random_pet.suffix.id}-worker-${count.index + 1}"
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
    name              = "${var.cluster_name}-${random_pet.suffix.id}-worker-${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 30
  }

  os_profile {
    computer_name  = "${var.cluster_name}-${random_pet.suffix.id}-worker-${count.index + 1}"
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
      "cluster" = "${var.cluster_name}-${random_pet.suffix.id}"
      "role"    = "worker"
    },
  )
}

