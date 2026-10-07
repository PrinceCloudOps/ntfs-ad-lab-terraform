provider "azurerm" {
  features {}
}

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "RG-Hybrid-Identity-Lab"
  location = var.location
}

# 2. Virtual Network & Subnet
resource "azurerm_virtual_network" "vnet" {
  name                = "VNet-Core"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "Subnet-Servers"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 3. Public IP & Network Interface for DC01
resource "azurerm_public_ip" "dc01_pip" {
  name                = "pip-dc01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "dc01_nic" {
  name                = "nic-dc01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.dc01_pip.id
  }
}

# 4. Windows Server 2022 Virtual Machine (DC01)
resource "azurerm_windows_virtual_machine" "dc01" {
  name                = "DC01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.dc01_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}
# 5. Promote DC01 to an Active Directory Domain Controller
resource "azurerm_virtual_machine_extension" "promote_dc" {
  name                 = "promote-dc"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc01.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute": "powershell.exe -Command \"$Password = ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force; Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools; Install-ADDSForest -DomainName 'blakecloudsolutions.local' -SafeModeAdministratorPassword $Password -InstallDns -Force; Restart-Computer -Force\""
    }
  PROTECTED_SETTINGS
}
# 6. Network Security Group (NSG) to secure RDP
resource "azurerm_network_security_group" "nsg" {
  name                = "NSG-Core"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*" # For lab testing, * is fine. In enterprise, this is locked to a VPN IP.
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
# ==========================================
# File Server (FS01) Infrastructure
# ==========================================

resource "azurerm_network_interface" "fs01_nic" {
  name                = "nic-fs01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "fs01_vm" {
  name                = "FS01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s" # Cost-effective size for lab file server
  admin_username      = "sysadmin"
  admin_password = "HybridIdentityLab2026!"
  network_interface_ids = [
    azurerm_network_interface.fs01_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}