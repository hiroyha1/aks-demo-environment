variable "admin_username" {}
variable "admin_password" {}
variable "resource_group_name" {}
variable "location" {}
variable "name" {}
variable "zone" {
  default = 1
}
variable "vm_size" {
  default = "Standard_B2ms"
}
variable "subnet_id" {}
variable "custom_data" {}

resource "azurerm_public_ip" "pip" {
  name                = "pip-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_linux_virtual_machine" "linux" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  zone                            = var.zone
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  custom_data = base64encode(var.custom_data)
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

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
}
resource "azurerm_network_security_rule" "nsg-rule" {
  name                        = "remote_access"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["22", "80"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
resource "azurerm_subnet_network_security_group_association" "nsg-assosiation" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
output "nic_id" {
  value = azurerm_network_interface.nic.id
}
output "ip_configuration_name" {
  value = azurerm_network_interface.nic.ip_configuration[0].name
}
output "private_ip_address" {
  value = azurerm_network_interface.nic.private_ip_address
}