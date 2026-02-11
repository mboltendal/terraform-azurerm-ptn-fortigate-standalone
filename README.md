# terraform-azurerm-ptn-fortigate-standalone

Terraform module that deploys a standalone FortiGate NVA (Network Virtual Appliance) on Azure.

## Features

- Deploys a FortiGate VM with dual-NIC topology (external/wan + internal/lan)
- Supports both BYOL and PAYG licensing
- SSH key or password authentication
- Optional public IP creation or bring-your-own public IP
- Configurable bootstrap configuration via custom data
- User-assigned managed identity (create new or bring existing)
- Availability zone placement
- Accelerated networking support
- IP forwarding enabled on both NICs

## Architecture

```
                    ┌──────────────┐
                    │  Public IP   │ (optional)
                    └──────┬───────┘
                           │
              ┌────────────┴────────────┐
              │   External NIC (port1)  │  ← WAN / untrust
              │   - DHCP                │
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
              │   - DHCP                │
              │   - IP forwarding       │
              └─────────────────────────┘
```

## Usage

```hcl
module "fortigate" {
  source = "github.com/<org>/terraform-azurerm-ptn-fortigate-standalone"

  parent_id = azurerm_resource_group.example.id
  name      = "vm-fw-prod-weu"
  location  = "westeurope"

  admin_password         = var.admin_password
  fortigate_license_type = "payg"

  external_subnet_id        = module.network.subnets["external"].resource_id
  internal_subnet_id        = module.network.subnets["internal"].resource_id
  create_external_public_ip = true

  tags = {
    Environment = "Production"
  }
}
```

See the [examples/basic](examples/basic) directory for a complete working example.

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
| [azurerm_public_ip.external](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_user_assigned_identity.fortigate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| parent_id | The ID of the resource group where resources will be deployed. | `string` | n/a | yes |
| name | The name of the FortiGate VM. | `string` | n/a | yes |
| fortigate_license_type | The license type of the FortiGate image (`byol` or `payg`). | `string` | n/a | yes |
| external_subnet_id | The ID of the subnet for the external NIC (port1). | `string` | n/a | yes |
| internal_subnet_id | The ID of the subnet for the internal NIC (port2). | `string` | n/a | yes |
| location | Azure region for resources. | `string` | `"west europe"` | no |
| vm_size | The size of the FortiGate VM. | `string` | `"Standard_F2s_v2"` | no |
| admin_username | The admin username for the FortiGate VM. | `string` | `"fgadmin"` | no |
| admin_password | The admin password for the FortiGate VM. Required if no SSH key is provided. | `string` | `null` | no |
| admin_ssh_key | The SSH public key for the FortiGate VM. Required if no password is provided. | `string` | `null` | no |
| fortigate_version | The version of the FortiGate image. | `string` | `"latest"` | no |
| enable_accelerated_networking | Enable accelerated networking on the FortiGate NICs. | `bool` | `true` | no |
| create_external_public_ip | Create and attach a new Public IP for the external NIC. | `bool` | `false` | no |
| external_public_ip_id | Existing Public IP resource ID to attach when `create_external_public_ip` is false. | `string` | `null` | no |
| public_ip_sku | SKU for a created public IP (`Standard` or `Basic`). | `string` | `"Standard"` | no |
| public_ip_allocation_method | Allocation method for a created public IP (`Static` or `Dynamic`). | `string` | `"Static"` | no |
| public_ip_tags | Tags to apply to the created public IP. | `map(string)` | `{}` | no |
| fortigate_custom_data | Custom data (bootstrap config) to be passed to the FortiGate VM. | `string` | `null` | no |
| zone | The availability zone to deploy the FortiGate VM into. | `string` | `null` | no |
| managed_identity_id | Existing user-assigned managed identity ID. If not provided, a new identity will be created. | `string` | `null` | no |
| tags | Tags to apply to all resources. | `map(string)` | `{}` | no |

> **Note:** Either `admin_password` or `admin_ssh_key` must be provided.

## Outputs

| Name | Description |
|------|-------------|
| resource_group | The Resource Group where the FortiGate resources are deployed (id, name, location). |
| vm | The FortiGate VM details (id, name, location, size). |
| external_nic | The external NIC / port1 details (id, name, private_ip_address). |
| internal_nic | The internal NIC / port2 details (id, name, private_ip_address). |
| external_public_ip_id | The public IP ID attached to the external NIC (if any). |
| external_public_ip_address | The public IP address created for the external NIC (if any). |
| managed_identity_id | The managed identity ID assigned to the FortiGate VM. |

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
