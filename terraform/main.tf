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

# 5. Azure Databricks Access Connector for Unity Catalog Storage Integration
resource "azurerm_databricks_access_connector" "unity" {
  name                = "dbx-access-connector-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  identity {
    type = "SystemAssigned"
  }
}

# 6. Assign Storage Blob Data Contributor Role to Access Connector
resource "azurerm_role_assignment" "access_connector_blob_contributor" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.unity.identity[0].principal_id
}

# 7. Unity Catalog Storage Credential using Azure Managed Identity
resource "databricks_storage_credential" "external_mi" {
  name = "mi_storage_credential_${var.environment}"

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.unity.id
  }

  comment       = "Updated storage credential managed by Terraform via Azure Access Connector"
  force_destroy = true
  force_update  = true
  depends_on    = [azurerm_role_assignment.access_connector_blob_contributor]
}

# 8. Unity Catalog External Location for Raw Data Container
resource "databricks_external_location" "raw_location" {
  name            = "raw_data_external_location_${var.environment}"
  url             = "abfss://${azurerm_storage_container.raw_layer.name}@${azurerm_storage_account.datalake.name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.external_mi.name
  comment         = "External location for raw data lake container managed by Terraform"
  force_destroy   = true
  force_update    = true
}

# 9. Unity Catalog Grants on External Location
resource "databricks_grants" "raw_location_grants" {
  external_location = databricks_external_location.raw_location.id

  grant {
    principal  = "account users"
    privileges = ["READ_FILES", "WRITE_FILES"]
  }
}

# 10. Provision Dedicated Unity Catalog & Schema via Terraform
resource "databricks_catalog" "ml_catalog" {
  name          = "ml_catalog_${var.environment}"
  storage_root  = "${databricks_external_location.raw_location.url}catalogs/ml_catalog"
  comment       = "Dedicated Unity Catalog for ML artifacts managed by Terraform"
  force_destroy = true
  depends_on    = [databricks_external_location.raw_location]
}

resource "databricks_schema" "ml_schema" {
  catalog_name  = databricks_catalog.ml_catalog.name
  name          = "ml"
  comment       = "Managed Unity Catalog schema for ML model staging and artifacts"
  force_destroy = true
}

# 11. Unity Catalog Volume for MLflow Spark ML Staging
resource "databricks_volume" "mlflow_tmp_volume" {
  name         = "mlflow_tmp"
  catalog_name = databricks_schema.ml_schema.catalog_name
  schema_name  = databricks_schema.ml_schema.name
  volume_type  = "MANAGED"
  comment      = "Managed UC Volume for MLflow Spark ML temporary model staging (dfs_tmpdir)"
}

# 12. Automatically Upload Notebooks from local folder to Databricks
resource "databricks_notebook" "ingestion_notebook" {
  source = "${path.module}/../notebooks/01_data_ingestion_and_cleaning.ipynb"
  path   = "/Shared/notebooks/01_data_ingestion_and_cleaning"
  format = "JUPYTER"
}

resource "databricks_notebook" "rfm_ml_notebook" {
  source = "${path.module}/../notebooks/02_rfm_feature_engineering_and_ml.ipynb"
  path   = "/Shared/notebooks/02_rfm_feature_engineering_and_ml"
  format = "JUPYTER"
}

# 13. Create an Automated MLOps Job Workflow (Serverless Compute)
resource "databricks_job" "mlops_pipeline_job" {
  name = "PySpark_MLOps_Pipeline_Job"

  environment {
    environment_key = "serverless_ml_env"
    spec {
      environment_version = "4"
      dependencies = [
        "kagglehub"
      ]
    }
  }

  # Task 1: Data Ingestion & Cleaning
  task {
    task_key        = "data_ingestion_task"
    environment_key = "serverless_ml_env"

    notebook_task {
      notebook_path = databricks_notebook.ingestion_notebook.path
      base_parameters = {
        "STORAGE_ACCOUNT_NAME" = azurerm_storage_account.datalake.name
      }
    }
  }

  # Task 2: RFM Feature Engineering & ML Training (runs after Task 1)
  task {
    task_key        = "rfm_ml_training_task"
    environment_key = "serverless_ml_env"

    depends_on {
      task_key = "data_ingestion_task"
    }

    notebook_task {
      notebook_path = databricks_notebook.rfm_ml_notebook.path
      base_parameters = {
        "STORAGE_ACCOUNT_NAME" = azurerm_storage_account.datalake.name
        "MLFLOW_DFS_TMP"       = "/Volumes/${databricks_volume.mlflow_tmp_volume.catalog_name}/${databricks_volume.mlflow_tmp_volume.schema_name}/${databricks_volume.mlflow_tmp_volume.name}"
      }
    }
  }

  schedule {
    quartz_cron_expression = "0 0 6 * * ?" # Runs daily at 6 AM
    timezone_id            = "UTC"
  }
}

