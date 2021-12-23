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

resource "azurerm_public_ip" "hub_pip" {
  name                = "${var.hub_prefix}-${upper(var.hub_location)}-GATEWAYPIP"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  sku                 = "Basic"
  allocation_method   = "Dynamic"
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
    public_ip_address_id          = azurerm_public_ip.hub_pip.id
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