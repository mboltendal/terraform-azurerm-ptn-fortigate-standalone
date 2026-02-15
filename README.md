# terraform-azurerm-ptn-fortigate-standalone

Terraform module that deploys a standalone FortiGate NVA (Network Virtual Appliance) on Azure.

## Features

- Deploys a FortiGate VM with dual-NIC topology (external/wan + internal/lan)
- Supports both BYOL and PAYG licensing
- SSH key or password authentication
- Bring-your-own public IPs for the external NIC (multiple supported)
- Configurable bootstrap configuration via custom data
- User-assigned managed identity (create new or bring existing)
- Availability zone placement
- Accelerated networking support with per-NIC overrides
- IP forwarding enabled on both or individual NICs

## Architecture

```
          ┌──────────────┐
          │  Public IPs  │ (user-managed)
          └──────┬───────┘
                 │
    ┌────────────┴────────────┐
    │   External NIC (port1)  │  ← WAN / untrust
    │   - DHCP (or static)    │
    │   - IP forwarding       │
    └────────────┬────────────┘
                 │
        ┌────────┴────────┐
        │   FortiGate VM  │
        │   (Standalone)  │
        └────────┬────────┘
                 │
    ┌────────────┴────────────┐
    │   Internal NIC (port2)  │  ← LAN / trust
    │   - DHCP (or static)    │
    │   - IP forwarding       │
    └─────────────────────────┘
```

## Usage

```hcl
module "fortigate" {
  source = "github.com/mboltendal/terraform-azurerm-ptn-fortigate-standalone"

  parent_id = azurerm_resource_group.example.id
  name      = "vm-fw-prod-weu"
  location  = "westeurope"

  admin_password         = var.admin_password
  fortigate_license_type = "payg"

  external_nic = {
    subnet_id = module.network.subnets["external"].resource_id
    ip_map = {
      primary = {
        public_ip_id = azurerm_public_ip.fortigate_primary.id
        primary      = true
      }
      secondary = {
        public_ip_id = azurerm_public_ip.fortigate_secondary.id
      }
    }
  }

  internal_nic = {
    subnet_id = module.network.subnets["internal"].resource_id
  }

  tags = {
    Environment = "Production"
  }
}
```

See the [examples](examples) directory for complete working examples.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 4.59 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 4.59 |

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_virtual_machine.fortigate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.external](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.internal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_user_assigned_identity.fortigate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admin_password | The admin password for the FortiGate VM. Required if no SSH key is provided. | `string` | `null` | no |
| admin_ssh_key | The SSH public key for the FortiGate VM. Required if no password is provided. | `string` | `null` | no |
| admin_username | The admin username for the FortiGate VM. | `string` | `"fgadmin"` | no |
| create_managed_identity | Whether to create a new user-assigned managed identity. Set to `false` when supplying `managed_identity_id` (especially if it is computed). | `bool` | `true` | no |
| enable_accelerated_networking | Default accelerated networking setting for the FortiGate NICs. | `bool` | `true` | no |
| external_nic | External NIC configuration. Exactly one IP configuration must be primary. | `object({ subnet_id = string, accelerated_networking_enabled = optional(bool), ip_map = map(object({ public_ip_id = string, name = optional(string), private_ip_address_allocation = optional(string, "Dynamic"), private_ip_address = optional(string), primary = optional(bool, false) })) })` | n/a | yes |
| fortigate_custom_data | Custom data (bootstrap config) to be passed to the FortiGate VM. | `string` | `null` | no |
| fortigate_license_type | The license type of the FortiGate image (`byol` or `payg`). | `string` | n/a | yes |
| fortigate_version | The version of the FortiGate image. | `string` | `"latest"` | no |
| internal_nic | Internal NIC configuration. | `object({ subnet_id = string, accelerated_networking_enabled = optional(bool), private_ip_address_allocation = optional(string, "Dynamic"), private_ip_address = optional(string) })` | n/a | yes |
| location | Azure region for resources. | `string` | `"west europe"` | no |
| managed_identity_id | Existing user-assigned managed identity ID. If not provided, a new identity will be created. | `string` | `null` | no |
| name | The name of the FortiGate VM. | `string` | n/a | yes |
| parent_id | The ID of the resource group where resources will be deployed. | `string` | n/a | yes |
| tags | Tags to apply to all resources. | `map(string)` | `{}` | no |
| vm_size | The size of the FortiGate VM. | `string` | `"Standard_F4s_v2"` | no |
| zone | The availability zone to deploy the FortiGate VM into. | `string` | `null` | no |

> **Note:** Either `admin_password` or `admin_ssh_key` must be provided.

## Outputs

| Name | Description |
|------|-------------|
| external_nic | The external NIC / port1 details (id, name, private_ip_address, ip_configuration). |
| internal_nic | The internal NIC / port2 details (id, name, private_ip_address, ip_configuration). |
| managed_identity_id | The managed identity ID assigned to the FortiGate VM. |
| resource_group | The Resource Group where the FortiGate resources are deployed (id, name, location). |
| vm | The FortiGate VM details (id, name, location, size). |

## Default Bootstrap Configuration

When `fortigate_custom_data` is not provided, the module applies a default bootstrap that:

- Sets the hostname to `FortiGate-Azure`
- Configures port1 (external) with DHCP, allowing ping/HTTPS/SSH
- Configures port2 (internal) with DHCP, allowing ping only
- Sets the management port to 8443
- Adds static routes for Azure metadata and DHCP relay
- Configures an outbound NAT policy (port2 -> port1) for HTTP/HTTPS
- Enables HTTP probe response on port 8008 (for load balancer health probes)
- Sets HA mode to standalone

To provide your own configuration, pass a FortiOS config string to `fortigate_custom_data`.

## License

Apache 2.0 - See [LICENSE](LICENSE) for details.
