terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "management_ips" {
  description = "List of IPs allowed to access the management interface"
  type        = list(string)
}

variable "admin_password" {
  description = "Admin password for the FortiGate VM"
  type        = string
  sensitive   = true
}