provider "azurerm" {
  features {}
  subscription_id = "7c9496c4-ef8b-44de-9b09-1c2022099887"
}

resource "azurerm_resource_group" "rg" {
  name     = "bistec-dhanu-aks-rg"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "bistec-dhanu-aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "dhanu-aks"
  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }
  identity {
    type = "SystemAssigned"
  }
}