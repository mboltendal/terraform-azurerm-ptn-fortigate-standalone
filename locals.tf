locals {
  resource_group_id   = var.parent_id
  resource_group_name = split("/", var.parent_id)[4]

  fortigate_image = {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku       = var.fortigate_license_type == "byol" ? "fortinet_fg-vm" : "fortinet_fg-vm_payg_2023"
    version   = var.fortigate_version
  }

  fortigate_config = var.fortigate_custom_data != null ? var.fortigate_custom_data : templatefile("${path.module}/templates/fortigate-config.tpl", {
    admin_username = var.admin_username
    admin_ssh_key  = var.admin_ssh_key
  })

  managed_identity_id = var.create_managed_identity ? azurerm_user_assigned_identity.fortigate[0].id : var.managed_identity_id

}
