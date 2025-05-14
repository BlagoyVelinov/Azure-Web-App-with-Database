terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.28.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "Need to add subscription_id"
}

resource "random_integer" "randomInt" {
  min = 10000
  max = 99999
}

resource "azurerm_resource_group" "arg" {
  name     = "ContactGroupRg${random_integer.randomInt.result}"
  location = "Italy North"
}

resource "azurerm_service_plan" "asp" {
  name                = "ContactsBookServicePlan${random_integer.randomInt.result}"
  resource_group_name = azurerm_resource_group.arg.name
  location            = azurerm_resource_group.arg.location
  os_type             = "Linux"
  sku_name            = "F1"
}