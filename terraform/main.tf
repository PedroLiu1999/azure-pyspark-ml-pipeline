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

# 5. Databricks Single-Node PySpark ML Cluster
resource "databricks_cluster" "ml_cluster" {
  cluster_name            = "pyspark-ml-cluster-${var.environment}"
  spark_version           = "14.3.x-cpu-ml-scala2.12" # Modern LTS ML runtime (Spark 3.5.0)
  node_type_id            = "Standard_D4s_v3"        # Supported Databricks VM size (4 vCPUs)
  num_workers             = 0                        # Explicitly single-node (1 node = 4 vCPUs total)
  autotermination_minutes = 30

  spark_conf = {
    "spark.master" = "local[*]"
    # Auto-authenticate Databricks to ADLS Gen2 Storage
    "fs.azure.account.key.${azurerm_storage_account.datalake.name}.dfs.core.windows.net" = azurerm_storage_account.datalake.primary_access_key
    "spark.storage.account.name" = azurerm_storage_account.datalake.name
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }
}


# 6. Automatically Upload Notebooks from local folder to Databricks
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

# 7. Create an Automated MLOps Job Workflow (Multi-task DAG)
resource "databricks_job" "mlops_pipeline_job" {
  name = "PySpark_MLOps_Pipeline_Job"

  # Task 1: Data Ingestion & Cleaning
  task {
    task_key            = "data_ingestion_task"
    existing_cluster_id = databricks_cluster.ml_cluster.id

    notebook_task {
      notebook_path = databricks_notebook.ingestion_notebook.path
    }
  }

  # Task 2: RFM Feature Engineering & ML Training (runs after Task 1)
  task {
    task_key            = "rfm_ml_training_task"
    existing_cluster_id = databricks_cluster.ml_cluster.id

    depends_on {
      task_key = "data_ingestion_task"
    }

    notebook_task {
      notebook_path = databricks_notebook.rfm_ml_notebook.path
    }
  }

  schedule {
    quartz_cron_expression = "0 0 6 * * ?" # Runs daily at 6 AM
    timezone_id            = "UTC"
  }
}

