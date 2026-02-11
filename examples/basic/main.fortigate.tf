resource "azurerm_resource_group" "fortigate" {
  name     = "rg-fortigate-dev-weu"
  location = "westeurope"
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

  admin_password = var.admin_password

  fortigate_license_type = "payg"

  enable_accelerated_networking = false
  create_external_public_ip     = true
  external_subnet_id            = module.network.subnets["external"].resource_id
  internal_subnet_id            = module.network.subnets["internal"].resource_id
}
