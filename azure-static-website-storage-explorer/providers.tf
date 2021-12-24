terraform {
  required_version = "~> 1.0"
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 2.0"
    }

    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }
  }

    backend "azurerm" {
        resource_group_name  = "terraform-global"
        storage_account_name = "terraformstatepjepam"
        container_name       = "terraformstate"
        key                  = "terraform.tfstate"
    }
}
provider "azurerm" {

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id

  features {
    
  }
}

