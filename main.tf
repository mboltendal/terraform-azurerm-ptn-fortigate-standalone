
resource "azurerm_user_assigned_identity" "fortigate" {
  count               = var.create_managed_identity ? 1 : 0
  
  name                = "id-${var.name}"
  location            = var.location
  resource_group_name = local.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_interface" "external" {
  name                = "nic-${var.name}-external"
  location            = var.location
  resource_group_name = local.resource_group_name

  accelerated_networking_enabled = coalesce(try(var.external_nic.accelerated_networking_enabled, null), var.enable_accelerated_networking)
  ip_forwarding_enabled          = true

  dynamic "ip_configuration" {
    for_each = { for key in sort(keys(var.external_nic.ip_map)) : key => var.external_nic.ip_map[key] }

    content {
      name                          = coalesce(try(ip_configuration.value.name, null), "ipconfig-${ip_configuration.key}")
      subnet_id                     = var.external_nic.subnet_id
      private_ip_address_allocation = try(ip_configuration.value.private_ip_address_allocation, "Dynamic")
      private_ip_address            = try(ip_configuration.value.private_ip_address, null)
      public_ip_address_id          = try(ip_configuration.value.public_ip_id, null)
      primary                       = try(ip_configuration.value.primary, false)
    }
  }

  tags = var.tags
}

resource "azurerm_network_interface" "internal" {
  name                = "nic-${var.name}-internal"
  location            = var.location
  resource_group_name = local.resource_group_name

  accelerated_networking_enabled = coalesce(try(var.internal_nic.accelerated_networking_enabled, null), var.enable_accelerated_networking)
  ip_forwarding_enabled          = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.internal_nic.subnet_id
    private_ip_address_allocation = try(var.internal_nic.private_ip_address_allocation, "Dynamic")
    private_ip_address            = try(var.internal_nic.private_ip_address, null)
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "fortigate" {
  name                = var.name
  location            = var.location
  resource_group_name = local.resource_group_name
  size                = var.vm_size

  admin_username                  = var.admin_username
  admin_password                  = var.admin_ssh_key == null ? var.admin_password : null
  disable_password_authentication = var.admin_ssh_key != null

  dynamic "admin_ssh_key" {
    for_each = var.admin_ssh_key != null ? [1] : []

    content {
      username   = var.admin_username
      public_key = var.admin_ssh_key
    }
  }

  network_interface_ids = [
    azurerm_network_interface.external.id,
    azurerm_network_interface.internal.id
  ]

  source_image_reference {
    publisher = local.fortigate_image.publisher
    offer     = local.fortigate_image.offer
    sku       = local.fortigate_image.sku
    version   = local.fortigate_image.version
  }

  plan {
    name      = local.fortigate_image.sku
    publisher = local.fortigate_image.publisher
    product   = local.fortigate_image.offer
  }

  os_disk {
    name                 = "${var.name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  custom_data = base64encode(local.fortigate_config)

  identity {
    type = "UserAssigned"
    identity_ids = [
      local.managed_identity_id
    ]
  }

  zone = var.zone

  tags = var.tags
}
