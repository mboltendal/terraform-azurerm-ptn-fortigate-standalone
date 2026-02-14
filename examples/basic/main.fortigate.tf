resource "azurerm_resource_group" "fortigate" {
  name     = "rg-fortigate-dev-weu"
  location = "westeurope"
}

resource "azurerm_public_ip" "fortigate_primary" {
  name                = "pip-fortigate-primary-dev-weu"
  location            = azurerm_resource_group.fortigate.location
  resource_group_name = azurerm_resource_group.fortigate.name

  allocation_method = "Static"
  sku               = "Standard"
}

module "fortigate" {
  source = "../../"

  parent_id = azurerm_resource_group.fortigate.id
  name      = "vm-platform-fw-dev-weu"
  location  = azurerm_resource_group.fortigate.location
  tags = {
    Environment = "Development"
    Project     = "Fortigate Deployment"
  }

  vm_size        = "Standard_F2s_v2"
  admin_username = "fgadmin"
  admin_password = var.admin_password

  fortigate_license_type = "payg"

  enable_accelerated_networking = false
  external_nic = {
    subnet_id = module.network.subnets["external"].resource_id
    ip_map = {
      primary = {
        public_ip_id = azurerm_public_ip.fortigate_primary.id
        primary      = true
      }
    }
  }
  internal_nic = {
    subnet_id = module.network.subnets["internal"].resource_id
  }
}
