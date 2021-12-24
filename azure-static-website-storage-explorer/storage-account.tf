locals {
  rgname = "static-website-lab-rg"
  location = "eastus"
  storage_account_name = "storage"
}

resource "random_string" "random" {
  length           = 16
  special          = false
  lower            = true
   keepers = {
    # Generate a new id each time we switch to a new AMI id
    ami_id = "11"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = local.rgname
  location = local.location
}

resource "azurerm_storage_account" "storage" {
  name                     = "${local.storage_account_name}${lower(random_string.random.result)}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  enable_https_traffic_only = true
  static_website {
    index_document         = "index.html"
    error_404_document     = "error.html"
  }
}