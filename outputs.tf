output "resource_group" {
  description = "The Resource Group where the Fortigate resources are deployed"
  value = {
    id       = local.resource_group_id
    name     = local.resource_group_name
    location = var.location
  }
}

output "vm" {
  description = "The Fortigate VM details"
  value = {
    id       = azurerm_linux_virtual_machine.fortigate.id
    name     = azurerm_linux_virtual_machine.fortigate.name
    location = azurerm_linux_virtual_machine.fortigate.location
    size     = azurerm_linux_virtual_machine.fortigate.size
  }
}

output "external_nic" {
  description = "The external NIC (port1) details"
  value = {
    id                 = azurerm_network_interface.external.id
    name               = azurerm_network_interface.external.name
    ip_configuration = [
      for ip in azurerm_network_interface.external.ip_configuration : {
        name                          = ip.name
        subnet_id                     = ip.subnet_id
        private_ip_address_allocation = ip.private_ip_address_allocation
        private_ip_address            = ip.private_ip_address
        public_ip_address_id          = ip.public_ip_address_id
        primary                       = ip.primary
      }
    ]
  }
}

output "internal_nic" {
  description = "The internal NIC (port2) details"
  value = {
    id                 = azurerm_network_interface.internal.id
    name               = azurerm_network_interface.internal.name
    ip_configuration = [
      for ip in azurerm_network_interface.internal.ip_configuration : {
        name                          = ip.name
        subnet_id                     = ip.subnet_id
        private_ip_address_allocation = ip.private_ip_address_allocation
        private_ip_address            = ip.private_ip_address
        public_ip_address_id          = ip.public_ip_address_id
        primary                       = ip.primary
      }
    ]
  }
}

output "managed_identity_id" {
  description = "The managed identity ID assigned to the FortiGate VM."
  value       = local.managed_identity_id
}
