# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "kailunTFResourceGroup"
  location = "westus2"
  tags = {
    Environment = "Terraform Getting Started"
    Team = "DevOps"
  }
}

resource "azurerm_virtual_network" "vn" {
  name                = "kailunvn"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "sn" {
  name                 = "kailunsub"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = ["10.0.2.0/24"]
}

 resource "azurerm_public_ip" "pi" {
   name                         = "kailunpublicIP"
   location                     = azurerm_resource_group.rg.location
   resource_group_name          = azurerm_resource_group.rg.name
   allocation_method            = "Static"
 }

resource "azurerm_lb" "lb" {
    name                = "loadBalancer"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
 
    frontend_ip_configuration {
      name                 = "publicIPAddress"
      public_ip_address_id = azurerm_public_ip.pi.id
    }
  }
 
resource "azurerm_lb_backend_address_pool" "ap" {
    loadbalancer_id     = azurerm_lb.lb.id
    name                = "BackEndAddressPool"
}


# Create network interface
resource "azurerm_network_interface" "nic" {
    count                     = 2
    name                      = "kailunNIC${count.index}"
    location                  = azurerm_resource_group.rg.location
    resource_group_name       = azurerm_resource_group.rg.name

    ip_configuration {
        name                          = "kailunNicConfiguration"
        subnet_id                     = azurerm_subnet.sn.id
        private_ip_address_allocation = "Dynamic"
    }

}


resource "azurerm_managed_disk" "disk" {
    count                = 2
    name                 = "kailunDatadisk_existing_${count.index}"
    location             = azurerm_resource_group.rg.location
    resource_group_name  = azurerm_resource_group.rg.name
    storage_account_type = "Standard_LRS"
    create_option        = "Empty"
    disk_size_gb         = "1023"
}

resource "azurerm_availability_set" "avset" {
    name                         = "kailunavset"
    location                     = azurerm_resource_group.rg.location
    resource_group_name          = azurerm_resource_group.rg.name
    platform_fault_domain_count  = 2
    platform_update_domain_count = 2
    managed                      = true
}

resource "azurerm_virtual_machine" "vm" {
    count                 = 2
    name                  = "kaikunAcctvm${count.index}"
    location              = azurerm_resource_group.rg.location
    availability_set_id   = azurerm_availability_set.avset.id
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [element(azurerm_network_interface.nic.*.id, count.index)]
    vm_size               = "Standard_DS1_v2"
 
    # Uncomment this line to delete the OS disk automatically when deleting the VM
    delete_os_disk_on_termination = true
 
    # Uncomment this line to delete the data disks automatically when deleting the VM
    delete_data_disks_on_termination = true
 
    storage_image_reference {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "16.04-LTS"
      version   = "latest"
    }
 
    storage_os_disk {
      name              = "kailunosdisk${count.index}"
      caching           = "ReadWrite"
      create_option     = "FromImage"
      managed_disk_type = "Standard_LRS"
    }
 
    # Optional data disks
    storage_data_disk {
      name              = "kailundatadisk_new_${count.index}"
      managed_disk_type = "Standard_LRS"
      create_option     = "Empty"
      lun               = 0
      disk_size_gb      = "1023"
    }
 
    storage_data_disk {
      name            = element(azurerm_managed_disk.disk.*.name, count.index)
      managed_disk_id = element(azurerm_managed_disk.disk.*.id, count.index)
      create_option   = "Attach"
      lun             = 1
      disk_size_gb    = element(azurerm_managed_disk.disk.*.disk_size_gb, count.index)
    }
 
    os_profile {
      computer_name  = "kailun-vm"
      admin_username = "kailunshi"
      admin_password = "fake_password_123"
    }
 
    os_profile_linux_config {
      disable_password_authentication = false
    }
 
    tags = {
      environment = "kailun-dev"
    }
}
