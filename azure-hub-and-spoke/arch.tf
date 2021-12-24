//Hub - Resource Group
resource "azurerm_resource_group" "hub_rg" {
    name = "${var.hub_prefix}-${upper(var.hub_location)}-RG"
    location = var.hub_location
}

resource "azurerm_virtual_network" "hub_vnet" {
  name                = "${var.hub_prefix}-${upper(var.hub_location)}-VNET"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "hub_gw_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hub_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "hub_subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.hub_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "hub_firewallsubnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "hub_gw_pip" {
  name                = "${var.hub_prefix}-${upper(var.hub_location)}-GATEWAYPIP"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  sku                 = "Basic"
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "hub_fw_pip" {
  name                = "${var.hub_prefix}-${upper(var.hub_location)}-FWPIP"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_firewall_policy" "hub_fw_policy" {
  name                = "${var.hub_prefix}-${upper(var.hub_location)}-FIREWALLPOLICY"
  resource_group_name = azurerm_resource_group.hub_rg.name
  location            = azurerm_resource_group.hub_rg.location
}

resource "azurerm_firewall_policy_rule_collection_group" "hub_fw_policy_rule_01" {
  name               = "${var.hub_prefix}-${upper(var.hub_location)}-FWP-RCG-01"
  firewall_policy_id = azurerm_firewall_policy.hub_fw_policy.id
  priority           = 500

  network_rule_collection {
    name     = "FWP-RCG-01-NRC-01-ALLOW"
    priority = 400
    action   = "Allow"
    rule {
      name                  = "ONPREM-TO-SPOKE01"
      protocols             = ["Any"]
      source_addresses      = ["10.1.0.0/16"] //OnPrem
      destination_addresses = ["10.2.0.0/16"] //Spoke01
      destination_ports     = ["1-65535"]
    }
    rule {
      name                  = "ONPREM-TO-SPOKE02"
      protocols             = ["Any"]
      source_addresses      = ["10.1.0.0/16"] //OnPrem
      destination_addresses = ["10.3.0.0/16"] //Spoke02
      destination_ports     = ["1-65535"]
    }
    rule {
      name                  = "SPOKE01-TO-ONPREM"
      protocols             = ["Any"]
      source_addresses      = ["10.2.0.0/16"] //Spoke01
      destination_addresses = ["10.1.0.0/16"] //OnPrem
      destination_ports     = ["1-65535"]
    }
    rule {
      name                  = "SPOKE01-TO-SPOKE02"
      protocols             = ["Any"]
      source_addresses      = ["10.2.0.0/16"] //Spoke01
      destination_addresses = ["10.3.0.0/16"] //SPOKE02
      destination_ports     = ["1-65535"]
    }
    rule {
      name                  = "SPOKE02-TO-SPOKE01"
      protocols             = ["Any"]
      source_addresses      = ["10.3.0.0/16"] //Spoke01
      destination_addresses = ["10.2.0.0/16"] //SPOKE02
      destination_ports     = ["1-65535"]
    }
  }
  network_rule_collection {
    name     = "FWP-RCG-01-NRC-02-DENY"
    priority = 300
    action   = "Deny"
    rule {
      name                  = "SPOKE02-TO-ONPREM"
      protocols             = ["Any"]
      source_addresses      = ["10.3.0.0/16"] //Spoke02
      destination_addresses = ["10.1.0.0/16"] //OnPrem
      destination_ports     = ["1-65535"]
    }
  }
}

resource "azurerm_firewall" "hub_fw" {
  name                = "${var.hub_prefix}-${upper(var.hub_location)}-FIREWALL"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  sku_tier            = "Premium"
  sku_name            = "AZFW_VNet"
  firewall_policy_id  = azurerm_firewall_policy.hub_fw_policy.id
  ip_configuration {
    name                 = "${var.hub_prefix}-${upper(var.hub_location)}-FIREWALL-CONFIG"
    subnet_id            = azurerm_subnet.hub_firewallsubnet.id
    public_ip_address_id = azurerm_public_ip.hub_fw_pip.id
  }
}



resource "azurerm_virtual_network_gateway" "hub_gw" {
  name                = "${var.hub_prefix}-${upper(var.hub_location)}-VPNGW"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.hub_gw_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.hub_gw_subnet.id
  }
}

module "hub-vm" {
  source = "./modules/vm"
  rgname = azurerm_resource_group.hub_rg.name
  location = azurerm_resource_group.hub_rg.location
  name = "HUBVM1"
  prefix = "${var.hub_prefix}-${upper(var.hub_location)}"
  subnet_id = azurerm_subnet.hub_subnet1.id
  depends_on = [
    azurerm_virtual_network_gateway_connection.onprem_to_hub,
    azurerm_virtual_network_gateway_connection.hub_to_onprem
  ]
}


//onprem - Resource Group
resource "azurerm_resource_group" "onprem_rg" {
    name = "${var.onprem_prefix}-${upper(var.onprem_location)}-RG"
    location = var.onprem_location
}

resource "azurerm_virtual_network" "onprem_vnet" {
  name                = "${var.onprem_prefix}-${upper(var.onprem_location)}-VNET"
  location            = azurerm_resource_group.onprem_rg.location
  resource_group_name = azurerm_resource_group.onprem_rg.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "onprem_gw_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.onprem_rg.name
  virtual_network_name = azurerm_virtual_network.onprem_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "onprem_subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.onprem_rg.name
  virtual_network_name = azurerm_virtual_network.onprem_vnet.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_route_table" "onprem_gw_subnet_route" {
  name                          = "subnet1_route"
  location                      = azurerm_resource_group.onprem_rg.location
  resource_group_name           = azurerm_resource_group.onprem_rg.name
  disable_bgp_route_propagation = false

  route {
    name           = "route1"
    address_prefix = "10.2.0.0/16"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub_fw.ip_configuration[0].private_ip_address //Private IP Address is at index 1 
  }

}

resource "azurerm_subnet_route_table_association" "onprem_gw_subnet_route_assoc" {
  subnet_id      = azurerm_subnet.onprem_gw_subnet.id
  route_table_id = azurerm_route_table.onprem_gw_subnet_route.id
}

resource "azurerm_public_ip" "onprem_pip" {
  name                = "${var.onprem_prefix}-${upper(var.onprem_location)}-GATEWAYPIP"
  location            = azurerm_resource_group.onprem_rg.location
  resource_group_name = azurerm_resource_group.onprem_rg.name
  sku                 = "Basic"
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "onprem_gw" {
  name                = "${var.onprem_prefix}-${upper(var.onprem_location)}-VPNGW"
  location            = azurerm_resource_group.onprem_rg.location
  resource_group_name = azurerm_resource_group.onprem_rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.onprem_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.onprem_gw_subnet.id
  }
}
module "onprem-vm" {
  source = "./modules/vm"
  rgname = azurerm_resource_group.onprem_rg.name
  location = azurerm_resource_group.onprem_rg.location
  name = "ONPREMVM1"
  prefix = "${var.onprem_prefix}-${upper(var.onprem_location)}"
  subnet_id = azurerm_subnet.onprem_subnet1.id
  depends_on = [
    azurerm_virtual_network_gateway_connection.onprem_to_hub,
    azurerm_virtual_network_gateway_connection.hub_to_onprem
  ]
}

//Connections
resource "azurerm_virtual_network_gateway_connection" "onprem_to_hub" {
  name                = "onprem_to_hub_conn"
  location            = azurerm_resource_group.onprem_rg.location
  resource_group_name = azurerm_resource_group.onprem_rg.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.onprem_gw.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.hub_gw.id

  shared_key = var.pre_shared_key
}

resource "azurerm_virtual_network_gateway_connection" "hub_to_onprem" {
  name                = "hub_to_onprem_conn"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.hub_gw.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.onprem_gw.id

  shared_key = var.pre_shared_key
}


//Spoke01
//spoke01 - Resource Group
resource "azurerm_resource_group" "spoke01_rg" {
    name = "${var.spoke01_prefix}-${upper(var.spoke01_location)}-RG"
    location = var.spoke01_location
}

resource "azurerm_virtual_network" "spoke01_vnet" {
  name                = "${var.spoke01_prefix}-${upper(var.spoke01_location)}-VNET"
  location            = azurerm_resource_group.spoke01_rg.location
  resource_group_name = azurerm_resource_group.spoke01_rg.name
  address_space       = ["10.2.0.0/16"]
}


resource "azurerm_subnet" "spoke01_subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.spoke01_rg.name
  virtual_network_name = azurerm_virtual_network.spoke01_vnet.name
  address_prefixes     = ["10.2.0.0/24"]
}

resource "azurerm_route_table" "spoke01_subnet_route" {
  name                          = "subnet1_route"
  location                      = azurerm_resource_group.spoke01_rg.location
  resource_group_name           = azurerm_resource_group.spoke01_rg.name
  disable_bgp_route_propagation = false

  route {
    name           = "route1"
    address_prefix = "10.1.0.0/16"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub_fw.ip_configuration[0].private_ip_address //Private IP Address is at index 1 
  }

}

resource "azurerm_subnet_route_table_association" "spoke01_subnet_route_assoc" {
  subnet_id      = azurerm_subnet.spoke01_subnet1.id
  route_table_id = azurerm_route_table.spoke01_subnet_route.id
}



module "spoke01-vm" {
  source = "./modules/vm"
  rgname = azurerm_resource_group.spoke01_rg.name
  location = azurerm_resource_group.spoke01_rg.location
  name = "spoke01VM1"
  prefix = "${var.spoke01_prefix}-${upper(var.spoke01_location)}"
  subnet_id = azurerm_subnet.spoke01_subnet1.id
  depends_on = [
    azurerm_virtual_network_gateway_connection.onprem_to_hub,
    azurerm_virtual_network_gateway_connection.hub_to_onprem
  ]
}
//Network peering between spoke01 and hub
resource "azurerm_virtual_network_peering" "vnetpeer_spoke01_to_hub" {
  name                      = "vnetpeer_spoke01_to_hub"
  resource_group_name       = azurerm_resource_group.spoke01_rg.name
  virtual_network_name      = azurerm_virtual_network.spoke01_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
  depends_on = [
    azurerm_virtual_network.spoke01_vnet,
    azurerm_virtual_network.hub_vnet
  ]
}

resource "azurerm_virtual_network_peering" "vnetpeer_hub_to_spoke01" {
  name                      = "vnetpeer_hub_to_spoke01"
  resource_group_name       = azurerm_resource_group.hub_rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke01_vnet.id
  depends_on = [
    azurerm_virtual_network.spoke01_vnet,
    azurerm_virtual_network.hub_vnet
  ]
}