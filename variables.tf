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
  default     = "Standard_F4s_v2"
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
  description = "Default accelerated networking setting for the FortiGate NICs."
  type        = bool
  default     = true
}

variable "external_nic" {
  description = "External NIC configuration. Exactly one IP configuration must be primary."
  type = object({
    subnet_id                      = string
    accelerated_networking_enabled = optional(bool)
    ip_map = map(object({
      public_ip_id                  = string
      name                          = optional(string)
      private_ip_address_allocation = optional(string, "Dynamic")
      private_ip_address            = optional(string)
      primary                       = optional(bool, false)
    }))
  })

  validation {
    condition     = length(var.external_nic.ip_map) > 0
    error_message = "external_nic.ip_map must contain at least one IP configuration entry."
  }

  validation {
    condition     = length([for _, cfg in var.external_nic.ip_map : cfg if try(cfg.primary, false)]) == 1
    error_message = "external_nic.ip_map must contain exactly one entry with primary = true."
  }

  validation {
    condition = alltrue([
      for _, cfg in var.external_nic.ip_map : (
        try(cfg.private_ip_address, null) == null ||
        lower(try(cfg.private_ip_address_allocation, "Dynamic")) == "static"
      )
    ])
    error_message = "external_nic.ip_map entries with private_ip_address must set private_ip_address_allocation to Static."
  }
}

variable "internal_nic" {
  description = "Internal NIC configuration."
  type = object({
    subnet_id                      = string
    accelerated_networking_enabled = optional(bool)
    private_ip_address_allocation  = optional(string, "Dynamic")
    private_ip_address             = optional(string)
  })

  validation {
    condition = (
      try(var.internal_nic.private_ip_address, null) == null ||
      lower(try(var.internal_nic.private_ip_address_allocation, "Dynamic")) == "static"
    )
    error_message = "internal_nic.private_ip_address requires private_ip_address_allocation = Static."
  }
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