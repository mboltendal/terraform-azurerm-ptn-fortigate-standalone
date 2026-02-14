resource "azurerm_resource_group" "network" {
  name     = "rg-connectivity-dev-weu"
  location = "westeurope"
}

module "network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  name             = "vnet-platform-dev-weu"
  parent_id        = azurerm_resource_group.network.id
  location         = azurerm_resource_group.network.location
  enable_telemetry = false

  address_space = ["10.0.0.0/21"]

  subnets = {
    external = {
      name                            = "ExternalSubnet"
      address_prefixes                = ["10.0.0.0/24"]
      default_outbound_access_enabled = false
      network_security_group = {
        id = azurerm_network_security_group.external.id
      }
    }
    internal = {
      name                            = "InternalSubnet"
      address_prefixes                = ["10.0.1.0/24"]
      default_outbound_access_enabled = false
    }
    workload = {
      name                            = "WorkloadSubnet"
      address_prefixes                = ["10.0.2.0/24"]
      default_outbound_access_enabled = false
    }
  }
}

resource "azurerm_network_security_group" "external" {
  name                = "nsg-external-dev-weu"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.management_ips
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefixes    = var.management_ips
    destination_address_prefix = "*"
  }
}
