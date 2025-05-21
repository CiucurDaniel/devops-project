terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.21.1"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-devops-global-germanywestcentral-001"
    storage_account_name = "stdevopsglobalgwc001"
    container_name       = "tfstate-global"
    key                  = "devops-admin-vms"
  }
}

provider "azurerm" {
  # Configuration options
  features {}
  resource_provider_registrations = "core"
}

locals {
  project = "devops"
  env     = "global"
  region  = "germanywestcentral"
  name    = "${local.project}-vms-${local.env}-${local.region}-001"
}

data "azurerm_resource_group" "main" {
  name = "rg-${local.project}-${local.env}-${local.region}-001"
}

data "azurerm_subnet" "main" {
  name                 = "snet-${local.project}-vms-${local.env}-${local.region}-001"
  resource_group_name  = "rg-${local.project}-${local.env}-${local.region}-001"
  virtual_network_name = "vnet-${local.project}-${local.env}-${local.region}-001"
}

resource "azurerm_network_interface" "main" {
  name                = "nic-${local.name}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "main" {
  name                = "vm-${local.name}"
  computer_name       = "vm-${local.project}-migration"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  size                = "Standard_D4as_V5"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-24h2-pro"
    version   = "latest"
  }
}

resource "azurerm_network_security_group" "main" {
  name                = "nsg-${local.name}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

variable "admin_username" {
  description = "The admin username for the VM."
  type        = string
}

variable "admin_password" {
  description = "The admin password for the VM."
  type        = string
  sensitive   = true
}