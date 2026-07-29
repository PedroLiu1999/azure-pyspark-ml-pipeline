# Random string for globally unique storage account name
resource "random_string" "unique" {
  length  = 6
  special = false
  upper   = false
}

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-pyspark-portfolio-${var.environment}"
  location = var.location
}

# 2. Azure Data Lake Storage Gen2 Account
resource "azurerm_storage_account" "datalake" {
  name                     = "stspark${random_string.unique.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true # Enables Hierarchical Namespace (ADLS Gen2)
}

# 3. Storage Container for Data Lake Storage
resource "azurerm_storage_container" "raw_layer" {
  name                  = "raw-data"
  storage_account_name  = azurerm_storage_account.datalake.name
  container_access_type = "private"
}

# 4. Azure Databricks Workspace
resource "azurerm_databricks_workspace" "databricks" {
  name                = "dbx-portfolio-workspace-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "premium"
}