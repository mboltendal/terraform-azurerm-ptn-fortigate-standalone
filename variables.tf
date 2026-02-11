variable "parent_id" {
  description = "The ID of the resource group where resources will be deployed."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+$", var.parent_id))
    error_message = "parent_id must be a valid resource group ID."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "west europe"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "The name of the FortiGate VM."
  type        = string
}

variable "vm_size" {
  description = "The size of the FortiGate VM."
  type        = string
  default     = "Standard_F2s_v2"
}

variable "admin_username" {
  description = "The admin username for the FortiGate VM."
  type        = string
  default     = "fgadmin"
}

variable "admin_password" {
  description = "The admin password for the FortiGate VM. Required if no SSH key is provided."
  type        = string
  sensitive   = true
  default     = null

  validation {
    condition     = var.admin_password != null || var.admin_ssh_key != null
    error_message = "Either admin_password or admin_ssh_key must be provided."
  }
}

variable "admin_ssh_key" {
  description = "The SSH public key for the FortiGate VM. Required if no admin password is provided."
  type        = string
  default     = null
}

variable "fortigate_license_type" {
  description = "The license type of the FortiGate image (e.g., byol, payg)."
  type        = string

  validation {
    condition     = can(regex("^(byol|payg)$", var.fortigate_license_type))
    error_message = "fortigate_license_type must be either 'byol' or 'payg'."
  }
}

variable "fortigate_version" {
  description = "The version of the FortiGate image."
  type        = string
  default     = "latest"
}


# Networking Configuration
variable "enable_accelerated_networking" {
  description = "Enable accelerated networking on the FortiGate NICs."
  type        = bool
  default     = true
}

variable "external_subnet_id" {
  description = "The ID of the subnet to attach the external network interface (port1)."
  type        = string
}

variable "internal_subnet_id" {
  description = "The ID of the subnet to attach the internal network interface (port2)."
  type        = string
}

variable "create_external_public_ip" {
  description = "Create and attach a new Public IP for the external NIC."
  type        = bool
  default     = false
}

variable "external_public_ip_id" {
  description = "Existing Public IP resource ID to attach when create_external_public_ip is false."
  type        = string
  default     = null
}

variable "public_ip_sku" {
  description = "SKU for a created public IP (Standard or Basic)."
  type        = string
  default     = "Standard"
}

variable "public_ip_allocation_method" {
  description = "Allocation method for a created public IP (Static or Dynamic)."
  type        = string
  default     = "Static"
}

variable "public_ip_tags" {
  description = "Tags to apply to the created public IP."
  type        = map(string)
  default     = {}
}

variable "fortigate_custom_data" {
  description = "Custom data (cloud-init) to be passed to the FortiGate VM."
  type        = string
  default     = null
}

variable "zone" {
  description = "The availability zone to deploy the FortiGate VM into."
  type        = string
  default     = null
}

variable "managed_identity_id" {
  description = "Existing user-assigned managed identity ID. If not provided, a new identity will be created."
  type        = string
  default     = null
}