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

# 5. Automatically Upload Notebooks from local folder to Databricks
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

# 6. Create an Automated MLOps Job Workflow (Serverless Compute)
resource "databricks_job" "mlops_pipeline_job" {
  name = "PySpark_MLOps_Pipeline_Job"

  environment {
    environment_key = "serverless_ml_env"
    spec {
      environment_version = "3"
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
      }
    }
  }

  schedule {
    quartz_cron_expression = "0 0 6 * * ?" # Runs daily at 6 AM
    timezone_id            = "UTC"
  }
}

