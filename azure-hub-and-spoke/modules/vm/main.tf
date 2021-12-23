

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-${var.name}-NIC"
  location            = var.location
  resource_group_name = var.rgname

  ip_configuration {
    name                          = "${var.prefix}-${var.name}-ipconfig"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                  = "${var.prefix}-${var.name}"
  location              = var.location
  resource_group_name   = var.rgname
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = var.sku


  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username      = "azureuser"
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-${var.name}-PIP"
  location            = var.location
  resource_group_name = var.rgname
  sku                 = "Basic"
  allocation_method   = "Dynamic"
}