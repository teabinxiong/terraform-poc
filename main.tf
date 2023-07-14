resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "Terraform Azure"
  }
}


resource "azurerm_virtual_network" "vnet" {
  name                = "book-vnet"
  location            = "Southeast Asia"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "book-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.0.10.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "book-ip"
  location            = "Southeast Asia"
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = "bookdevops"
}

resource "azurerm_network_interface" "nic" {
  name                = "book-nic"
  location            = "Southeast Asia"
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "bookipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_storage_account" "stor" {
  name                     = "bookstorex11"
  location                 = "Southeast Asia"
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "bookvm"
  location                        = "Southeast Asia"
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B1s"
  network_interface_ids           = ["${azurerm_network_interface.nic.id}"]
  admin_username                  = "adminuser"
  admin_password                  = "P@$$w0rd1234!"
  disable_password_authentication = false
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "book-osdisk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.stor.primary_blob_endpoint
  }
}
