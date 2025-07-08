# ---------------------------
# Provider Block: Connects Terraform to Azure
# ---------------------------
provider "azurerm" {
  features {}  # Required block for azurerm provider
  subscription_id = ""  # Your Azure subscription
}

# ---------------------------
# Resource Group: Logical container for resources
# ---------------------------
resource "azurerm_resource_group" "rg" {
  name     = "packer-rg"
  location = "East US"
}

# ---------------------------
# Virtual Network (VNet): Defines a network space
# ---------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]  # IP range for the VNet
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# ---------------------------
# Subnet: A smaller range inside the VNet
# ---------------------------
resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  address_prefixes     = ["10.0.1.0/24"]  # Subnet IP range
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

# ---------------------------
# Network Security Group (NSG): Controls inbound/outbound traffic
# ---------------------------
resource "azurerm_network_security_group" "nsg" {
  name                = "nginx-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Rule to allow HTTP (port 80)
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Rule to allow SSH (port 22)
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ---------------------------
# Associate NSG with Subnet
# ---------------------------
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# ---------------------------
# Public IP Address: Needed to access VM from the internet
# ---------------------------
resource "azurerm_public_ip" "public_ip" {
  name                = "nginx-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"  # IP stays the same
  sku                 = "Standard"  # Needed for VM scale sets, Load Balancer, etc.
}

# ---------------------------
# Network Interface Card (NIC): Connects VM to the network
# ---------------------------
resource "azurerm_network_interface" "nic" {
  name                = "nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"  # Azure assigns an internal IP
    public_ip_address_id          = azurerm_public_ip.public_ip.id  # Attach public IP
  }
}

# ---------------------------
# Virtual Machine (VM): The actual Linux server
# ---------------------------
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "nginx-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"  # Low-cost VM size
  admin_username      = "azureuser"    # Login username
  disable_password_authentication = true  # Only allow SSH key login

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  # Use custom image created with Packer
  source_image_id = "/subscriptions/<your-subscription-id>/resourceGroups/packer-images-rg/providers/Microsoft.Compute/images/myPackerImage-v2"

  # SSH public key for authentication
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/azure_vm_key.pub")  # Path to your public SSH key
  }

  # OS disk configuration
  os_disk {
    name                 = "nginx-vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
