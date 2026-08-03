# Azure PySpark & ML Pipeline - Infrastructure Setup (Terraform)

This folder contains the Infrastructure as Code (IaC) configuration using **Terraform** to provision the core Azure cloud resources and Databricks governance/jobs required for the PySpark Data Lake & ML Pipeline.

---

## 🏗️ Architecture Provisioned

The Terraform code in [`main.tf`](main.tf) provisions the following Azure and Databricks resources:

| Resource | Resource Name Pattern | Description |
| :--- | :--- | :--- |
| **Random String** | `random_string.unique` | Generates a 6-character random string to guarantee global uniqueness for the Azure Storage Account name. |
| **Resource Group** | `rg-pyspark-portfolio-${var.environment}` | Logical container for all project resources in the specified location. |
| **Azure Data Lake Storage Gen2** | `stspark<random_string>` | ADLS Gen2 Account with Hierarchical Namespace enabled (`is_hns_enabled = true`) for optimal PySpark read/write performance. |
| **Storage Container** | `raw-data` | Private storage container for storing raw and curated data lake layers. |
| **Azure Databricks Workspace** | `dbx-portfolio-workspace-${var.environment}` | **Premium SKU** Databricks workspace enabling Unity Catalog governance and Serverless compute. |
| **Databricks Access Connector** | `dbx-access-connector-${var.environment}` | Azure Access Connector configured with System-Assigned Managed Identity for passwordless ADLS Gen2 access. |
| **Blob Contributor Role Assignment** | `access_connector_blob_contributor` | Grants `Storage Blob Data Contributor` role to the Access Connector's principal ID on the storage account. |
| **Unity Catalog Storage Credential** | `mi_storage_credential_${var.environment}` | Databricks Unity Catalog storage credential backed by the Azure Access Connector Managed Identity. |
| **Unity Catalog External Location** | `raw_data_external_location_${var.environment}` | External location mapping `abfss://raw-data@<storage_account>.dfs.core.windows.net/` to Unity Catalog. |
| **Unity Catalog Grants** | `raw_location_grants` | Assigns `READ_FILES` and `WRITE_FILES` privileges on the external location to `account users`. |
| **Notebook Deployment** | `ingestion_notebook` & `rfm_ml_notebook` | Automatically syncs local notebooks to `/Shared/notebooks/` in the Databricks workspace. |
| **Serverless MLOps Job Pipeline** | `PySpark_MLOps_Pipeline_Job` | Multi-task DAG workflow using Serverless Compute (`serverless_ml_env`) with automated `kagglehub` library installation, scheduled daily at 6:00 AM UTC. |

---

## 📋 Prerequisites

1. **Azure CLI**: Installed and logged in (`az login`).
2. **Terraform CLI**: Version `>= 1.3.0` installed.
3. **Azure Subscription**: Active subscription with permissions to create Resource Groups, Storage Accounts, Databricks Workspaces, and Role Assignments.

---

## ⚙️ Configuration Files

* [**`providers.tf`**](providers.tf): Sets minimum Terraform version (`>= 1.3.0`), provider dependencies (`azurerm`, `databricks`, `random`), and configures `skip_provider_registration = true` to bypass lengthy provider checks on restricted subscriptions.
* [**`variables.tf`**](variables.tf): Defines input variables for `location` (default: `"Germany West Central"`) and `environment` (default: `"dev"`).
* [**`main.tf`**](main.tf): Defines all Azure cloud infrastructure, Unity Catalog credentials/locations, notebook sync, and Serverless MLOps job workflow.

---

## ⚠️ Key Configuration Gotchas & Solutions

### 1. Provider Registration Timeout / Slow `terraform plan`
* **Issue**: AzureRM provider attempts to auto-register 50+ Azure resource providers on every run, which hangs or times out on restricted subscriptions (such as Azure for Students).
* **Fix**: Added `skip_provider_registration = true` inside the `provider "azurerm"` block in [`providers.tf`](providers.tf#L16).

### 2. Azure Policy Region Restrictions (`RequestDisallowedByAzure`)
* **Issue**: Subscription policy restricts deployment to allowed Azure regions.
* **Fix**: Updated `location` in [`variables.tf`](variables.tf#L3) to `"Germany West Central"` (`germanywestcentral`).
* **Command to check allowed regions**:
  ```bash
  az policy assignment list --query "[?name=='sys.regionrestriction'].parameters.listOfAllowedLocations.value" --output json
  ```

### 3. Databricks Standard SKU Deprecation
* **Issue**: Azure deprecated `standard` SKU for new Databricks workspace creations (`DatabricksStandardSkuNotSupported`).
* **Fix**: Configured `sku = "premium"` in [`main.tf`](main.tf#L36).

### 4. Serverless MLOps Job Dependency Management
* **Issue**: Serverless compute environments in Databricks require explicit runtime dependencies for custom Python packages (e.g. `kagglehub`).
* **Fix**: Configured `environment` block with `serverless_ml_env` (environment version 3) and listed `kagglehub` under `dependencies` in [`main.tf`](main.tf#L104-L112).

---

## 🚀 Deployment Steps

### 1. Authenticate with Azure CLI
```bash
az login
```
*Select your active subscription when prompted.*

### 2. Navigate to the Terraform Directory
```bash
cd terraform
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Review the Execution Plan
```bash
terraform plan -out=tfplan
```

### 5. Apply Infrastructure Changes
```bash
terraform apply tfplan
```

### 6. Clean Up / Destroy Resources (When Finished)
```bash
terraform destroy
```
