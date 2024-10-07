terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.99.0"
    }
  }
}
provider "azurerm" {
  skip_provider_registration = true
  features {

  }
  subscription_id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  tenant_id       = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  client_id       = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  client_secret   = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}

resource "azurerm_resource_group" "dev" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "dev-vnet" {
  name                = "dev-vnet"
  address_space       = var.vnet
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
}

resource "azurerm_subnet" "bastion-subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.dev-vnet.name
  address_prefixes     = var.AzureBastionSubnet
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion-host" {
  name                = "AzureBastionHost"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  scale_units         = 2

  copy_paste_enabled     = true
  file_copy_enabled      = true
  shareable_link_enabled = true
  tunneling_enabled      = true

  ip_configuration {
    name                 = "ip1"
    subnet_id            = azurerm_subnet.bastion-subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

resource "azurerm_subnet" "web-subnet" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.dev-vnet.name
  address_prefixes     = var.web-subnet
}

resource "azurerm_availability_set" "webavset" {
  name                         = "webavset"
  resource_group_name          = azurerm_resource_group.dev.name
  location                     = azurerm_resource_group.dev.location
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_windows_virtual_machine" "webtier" {
  count                 = 2
  name                  = "webvm-${count.index + 1}"
  resource_group_name   = azurerm_resource_group.dev.name
  location              = azurerm_resource_group.dev.location
  network_interface_ids = [azurerm_network_interface.webtiernic[count.index].id]
  availability_set_id   = azurerm_availability_set.webavset.id
  size                  = "Standard_B2ms"
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "mydisk${count.index + 1}"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
  admin_username = "administrator1"
  admin_password = "Az@3TierConfig1234"
}

resource "azurerm_network_interface" "webtiernic" {
  count               = 2
  name                = "webvmnic-${count.index + 1}"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  ip_configuration {
    name                          = "webvmnicconfig"
    subnet_id                     = azurerm_subnet.web-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "webnsg" {
  name                = "webnsg"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  security_rule {
    name                       = "InboundHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "192.168.1.0/24"
  }
  security_rule {
    name                       = "OutboundDenyAll"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "192.168.1.0/24"
  }
}

resource "azurerm_subnet_network_security_group_association" "webnsgass" {
  subnet_id                 = azurerm_subnet.web-subnet.id
  network_security_group_id = azurerm_network_security_group.webnsg.id
}

resource "azurerm_public_ip" "PubLBIP" {
  name                = "PublicIPforFrontEndLB"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  allocation_method   = "Static"
}

resource "azurerm_lb" "InternetLB" {
  name                = "FrontEndLB"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  sku                 = "Basic"

  frontend_ip_configuration {
    name                 = "Front-EndLBIP"
    public_ip_address_id = azurerm_public_ip.PubLBIP.id

  }
}

resource "azurerm_lb_backend_address_pool" "BE_lb_pool" {
  loadbalancer_id = azurerm_lb.InternetLB.id
  name            = "BackEndPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "BE_nic_lb_pool" {
  count                 = 2
  network_interface_id  = azurerm_network_interface.webtiernic[count.index].id
  ip_configuration_name = "webvmnicconfig"

  backend_address_pool_id = azurerm_lb_backend_address_pool.BE_lb_pool.id
}

resource "azurerm_lb_probe" "FE_lb_probe" {
  loadbalancer_id = azurerm_lb.InternetLB.id
  name            = "FE_lb_probe"
  port            = 80
}

resource "azurerm_lb_rule" "FE_lb_rule" {
  loadbalancer_id                = azurerm_lb.InternetLB.id
  name                           = "FE_lb_rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  disable_outbound_snat          = true
  frontend_ip_configuration_name = "Front-EndLBIP"
  probe_id                       = azurerm_lb_probe.FE_lb_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.BE_lb_pool.id]
}

resource "azurerm_subnet" "app-subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.dev-vnet.name
  address_prefixes     = var.app-subnet
}

resource "azurerm_availability_set" "appavset" {
  name                         = "appavset"
  resource_group_name          = azurerm_resource_group.dev.name
  location                     = azurerm_resource_group.dev.location
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_windows_virtual_machine" "apptier" {
  count                 = 2
  name                  = "appvm-${count.index + 1}"
  resource_group_name   = azurerm_resource_group.dev.name
  location              = azurerm_resource_group.dev.location
  network_interface_ids = [azurerm_network_interface.apptiernic[count.index].id]
  availability_set_id   = azurerm_availability_set.appavset.id
  size                  = "Standard_B2ms"
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "mydisk${count.index + 1}"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
  admin_username = "administrator2"
  admin_password = "Az@3TierConfig1234"
}

resource "azurerm_network_interface" "apptiernic" {
  count               = 2
  name                = "appvmnic-${count.index + 1}"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  ip_configuration {
    name                          = "appvmnicconfig"
    subnet_id                     = azurerm_subnet.app-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "appnsg" {
  name                = "appnsg"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  security_rule {
    name                       = "InboundHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "192.168.2.0/24"
  }
  security_rule {
    name                       = "OutboundDenyAll"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "192.168.2.0/24"
  }
}

resource "azurerm_subnet_network_security_group_association" "appnsgass" {
  subnet_id                 = azurerm_subnet.app-subnet.id
  network_security_group_id = azurerm_network_security_group.appnsg.id
}


resource "azurerm_lb" "InternalLB1" {
  name                = "AppTierLB"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "WebTierLBIP"
    subnet_id                     = azurerm_subnet.web-subnet.id
    private_ip_address_allocation = "Dynamic"

  }
}

resource "azurerm_lb_backend_address_pool" "APPBE_lb_pool1" {
  loadbalancer_id = azurerm_lb.InternalLB1.id
  name            = "BackEndPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "APPBE_nic_lb_pool1" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.apptiernic[count.index].id
  ip_configuration_name   = "appvmnicconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.APPBE_lb_pool1.id
}

resource "azurerm_lb_probe" "APPFE_lb_probe1" {
  loadbalancer_id = azurerm_lb.InternalLB1.id
  name            = "FE_lb_probe"
  port            = 443
}

resource "azurerm_lb_rule" "APPFE_lb_rule1" {
  loadbalancer_id                = azurerm_lb.InternalLB1.id
  name                           = "FE_lb_rule"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  disable_outbound_snat          = true
  frontend_ip_configuration_name = "WebTierLBIP"
  probe_id                       = azurerm_lb_probe.APPFE_lb_probe1.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.APPBE_lb_pool1.id]
}

resource "azurerm_subnet" "db-subnet" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.dev-vnet.name
  address_prefixes     = var.db-subnet
}

resource "azurerm_availability_set" "dbavset" {
  name                         = "dbavset"
  resource_group_name          = azurerm_resource_group.dev.name
  location                     = azurerm_resource_group.dev.location
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_windows_virtual_machine" "dbtier" {
  count                 = 2
  name                  = "dbvm-${count.index + 1}"
  resource_group_name   = azurerm_resource_group.dev.name
  location              = azurerm_resource_group.dev.location
  network_interface_ids = [azurerm_network_interface.dbtiernic[count.index].id]
  availability_set_id   = azurerm_availability_set.dbavset.id
  size                  = "Standard_B1ms"
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "mydisk${count.index + 1}"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
  admin_username = "administrator2"
  admin_password = "Az@3TierConfig1234"
}

resource "azurerm_network_interface" "dbtiernic" {
  count               = 2
  name                = "dbvmnic-${count.index + 1}"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  ip_configuration {
    name                          = "dbvmnicconfig"
    subnet_id                     = azurerm_subnet.db-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "dbnsg" {
  name                = "dbnsg"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  security_rule {
    name                       = "InboundHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"
    destination_address_prefix = "192.168.3.0/24"
  }
  security_rule {
    name                       = "OutboundDenyAll"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "192.168.3.0/24"
  }
}

resource "azurerm_subnet_network_security_group_association" "dbnsgass" {
  subnet_id                 = azurerm_subnet.db-subnet.id
  network_security_group_id = azurerm_network_security_group.dbnsg.id
}

resource "azurerm_lb" "InternalLB2" {
  name                = "DbTierLB"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "DBTierLBIP"
    subnet_id                     = azurerm_subnet.app-subnet.id
    private_ip_address_allocation = "Dynamic"

  }
}

resource "azurerm_lb_backend_address_pool" "DBBE_lb_pool1" {
  loadbalancer_id = azurerm_lb.InternalLB2.id
  name            = "BackEndPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "DBBE_nic_lb_pool1" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.dbtiernic[count.index].id
  ip_configuration_name   = "dbvmnicconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.DBBE_lb_pool1.id
}

resource "azurerm_lb_probe" "DBFE_lb_probe1" {
  loadbalancer_id = azurerm_lb.InternalLB2.id
  name            = "FE_lb_probe"
  port            = 1433
}

resource "azurerm_lb_rule" "DBFE_lb_rule1" {
  loadbalancer_id                = azurerm_lb.InternalLB2.id
  name                           = "FE_lb_rule"
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  disable_outbound_snat          = true
  frontend_ip_configuration_name = "DBTierLBIP"
  probe_id                       = azurerm_lb_probe.DBFE_lb_probe1.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.DBBE_lb_pool1.id]
}
