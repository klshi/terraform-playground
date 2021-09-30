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
