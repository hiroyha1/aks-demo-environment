variable "zone" {
  default = 1
}
variable "vm_size" {
  default = "Standard_B2ms"
}
variable "admin_username" {}
variable "name" {}
variable "resource_group_name" {}
variable "location" {}
variable "admin_password" {}
variable "subnet_id" {}
resource "azurerm_public_ip" "pip" {
  name                = "pip-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "configuration"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}
resource "azurerm_windows_virtual_machine" "windows" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  zone                = var.zone
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  security_rule {
    name                       = "remote_access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}