output "https-endpoint" {
    value = azurerm_storage_account.storage.primary_web_endpoint
}

output "storage-account-name" {
    value = azurerm_storage_account.storage.name
}