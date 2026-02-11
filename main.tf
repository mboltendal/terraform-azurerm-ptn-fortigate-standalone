
resource "azurerm_user_assigned_identity" "fortigate" {
  count               = var.managed_identity_id == null ? 1 : 0
  name                = "${var.name}-mi"
  location            = var.location
  resource_group_name = local.resource_group_name
}

resource "azurerm_public_ip" "external" {
  count               = var.create_external_public_ip ? 1 : 0
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = local.resource_group_name

  allocation_method = var.public_ip_allocation_method
  sku               = var.public_ip_sku

  tags = merge(var.tags, var.public_ip_tags)
}

resource "azurerm_network_interface" "external" {
  name                = "${var.name}-nic-external"
  location            = var.location
  resource_group_name = local.resource_group_name

  accelerated_networking_enabled = var.enable_accelerated_networking
  ip_forwarding_enabled          = true

  ip_configuration {
    name                          = "external"
    subnet_id                     = var.external_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = local.external_public_ip_id
  }

  tags = var.tags
}

resource "azurerm_network_interface" "internal" {
  name                = "${var.name}-nic-internal"
  location            = var.location
  resource_group_name = local.resource_group_name

  accelerated_networking_enabled = var.enable_accelerated_networking
  ip_forwarding_enabled          = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.internal_subnet_id
    private_ip_address_allocation = "Dynamic"
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
