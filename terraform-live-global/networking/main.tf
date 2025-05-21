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
    key                  = "networking"
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "core"
}

locals {
  project = "devops"
  env     = "global"
  region  = "germanywestcentral"
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.project}-${local.env}-${local.region}-001"
  location = "Germany West Central"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.project}-${local.env}-${local.region}-001"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "snet-${local.project}-vms-${local.env}-${local.region}-001"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}