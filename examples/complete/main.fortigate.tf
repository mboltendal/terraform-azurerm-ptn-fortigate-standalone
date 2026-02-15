resource "azurerm_resource_group" "fortigate" {
  name     = "rg-fortigate-dev-weu"
  location = "westeurope"
}

resource "azurerm_user_assigned_identity" "fortigate" {
  name                = "mi-fortigate-dev-weu"
  location            = azurerm_resource_group.fortigate.location
  resource_group_name = azurerm_resource_group.fortigate.name
}

resource "azurerm_public_ip" "fortigate_primary" {
  name                = "pip-fortigate-primary-dev-weu"
  location            = azurerm_resource_group.fortigate.location
  resource_group_name = azurerm_resource_group.fortigate.name

  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_public_ip" "fortigate_secondary" {
  name                = "pip-fortigate-secondary-dev-weu"
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
    Project     = "FortiGate Deployment"
  }

  vm_size        = "Standard_F4s_v2"
  admin_username = "fgadmin"
  admin_password = var.admin_password

  fortigate_license_type = "payg"
  fortigate_version      = "latest"

  enable_accelerated_networking = false
  external_nic = {
    subnet_id                      = module.network.subnets["external"].resource_id
    accelerated_networking_enabled = true
    ip_map = {
      primary = {
        name                          = "ipconfig-primary"
        public_ip_id                  = azurerm_public_ip.fortigate_primary.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.0.0.4"
        primary                       = true
      }
      secondary = {
        name                          = "ipconfig-secondary"
        public_ip_id                  = azurerm_public_ip.fortigate_secondary.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.0.0.5"
      }
    }
  }
  internal_nic = {
    subnet_id                      = module.network.subnets["internal"].resource_id
    accelerated_networking_enabled = false
    private_ip_address_allocation  = "Static"
    private_ip_address             = "10.0.1.4"
  }

  # Add custom_data to configure the FortiGate VM on first boot
  # fortigate_custom_data = <<-EOT
  #   config system global
  #       set hostname "FortiGate-Complete"
  #       set admin-sport 8443
  #   end
  # EOT

  zone = null

  managed_identity_id = azurerm_user_assigned_identity.fortigate.id
}
