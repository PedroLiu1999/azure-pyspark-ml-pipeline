# 🚀 Azure PySpark & Databricks MLOps Pipeline: E-Commerce Customer Segmentation

[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![PySpark](https://img.shields.io/badge/PySpark-4.1.1+-E25A1C?style=flat&logo=apachespark&logoColor=white)](https://spark.apache.org/docs/latest/api/python/)
[![Delta Lake](https://img.shields.io/badge/Delta_Lake-4.3.1+-003366?style=flat&logo=delta-sharing&logoColor=white)](https://delta.io/)
[![Azure](https://img.shields.io/badge/Azure-Databricks%20%26%20ADLS%20Gen2-0089D6?style=flat&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![Terraform](https://img.shields.io/badge/Terraform-1.3+-844FBA?style=flat&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![MLflow](https://img.shields.io/badge/MLflow-Tracking-0194E2?style=flat&logo=mlflow&logoColor=white)](https://mlflow.org/)

An end-to-end, production-grade **Machine Learning & MLOps Pipeline** built with **PySpark**, **Delta Lake**, **Azure Databricks**, **Azure Data Lake Storage (ADLS Gen2)**, **Unity Catalog**, and **Terraform**.

This project processes raw e-commerce order transactions, performs automated data validation and cleaning, constructs **RFM (Recency, Frequency, Monetary)** features using PySpark SQL, saves curated data in **Delta Lake format**, trains an unsupervised **K-Means Clustering model** for customer segmentation with **MLflow** experiment tracking, and deploys the entire workflow via **Terraform Infrastructure as Code (IaC)** as a scheduled Serverless Databricks MLOps job.

---

## 📐 Architecture Overview

```
                                      ┌──────────────────────────────────────────────────────────────┐
                                      │                         AZURE CLOUD                          │
                                      │                                                              │
 ┌──────────────────────────┐         │  ┌────────────────────────┐   ┌───────────────────────────┐  │
 │  KaggleHub E-Commerce    │         │  │ Azure Data Lake (ADLS) │   │ Azure Databricks Workspace│  │
 │  Dataset (Raw Ingestion) │───────► │  │  Container: raw-data   │──►│ (Premium SKU)             │  │
 └──────────────────────────┘         │  └───────────▲────────────┘   └─────────────┬─────────────┘  │
                                      │              │                              │                │
                                      │              │ Unity Catalog Credential     │                │
                                      │              │ & External Location          │                │
                                      │  ┌───────────┴──────────────────────────────▼─────────────┐  │
                                      │  │ Azure Databricks Access Connector (Managed Identity)  │  │
                                      │  └──────────────────────────┬─────────────────────────────┘  │
                                      │                             │                                │
                                      │  ┌──────────────────────────▼─────────────────────────────┐  │
                                      │  │ Serverless Databricks MLOps Job (Multi-Task DAG)       │  │
                                      │  │                                                        │  │
                                      │  │  ┌──────────────────────────────────────────────────┐  │  │
                                      │  │  │ Task 1: 01_data_ingestion_and_cleaning         │  │  │
                                      │  │  │ (Ingestion, Delta Lake format & Table creation)  │  │  │
                                      │  │  └─────────────────────────┬────────────────────────┘  │  │
                                      │  │                            │                           │  │
                                      │  │  ┌─────────────────────────▼────────────────────────┐  │  │
                                      │  │  │ Task 2: 02_rfm_feature_engineering_and_ml     │  │  │
                                      │  │  │ (RFM Aggregation, K-Means & MLflow Logging)    │  │  │
                                      │  │  └──────────────────────────────────────────────────┘  │  │
                                      │  └────────────────────────────────────────────────────────┘  │
                                      └──────────────────────────────────────────────────────────────┘
```

---

## 🧰 Technology Stack

| Component | Technology | Purpose |
| :--- | :--- | :--- |
| **Data Processing** | [PySpark SQL & DataFrames](https://spark.apache.org/docs/latest/api/python/) (v4.1.1+) | Distributed data ingestion, schema enforcement, filtering, and cleaning. |
| **Storage Format** | [Delta Lake](https://delta.io/) (v4.3.1+) | ACID transactions, optimized storage (`cleaned_orders.delta`), and Catalog tables. |
| **Feature Aggregation** | PySpark SQL & Window Functions | RFM metric calculation (Recency, Frequency, Monetary, Return Rate). |
| **Machine Learning** | Scikit-Learn (`KMeans`, `StandardScaler`) & MLflow | Normalized customer segmentation ($K=3$), Silhouette Score, & MLflow model tracking. |
| **Data Visualization** | Seaborn & Matplotlib | Visual profiling of cluster spend distributions and metric summaries. |
| **Cloud Storage & Governance** | Azure ADLS Gen2 & Databricks Unity Catalog | Passwordless authentication via Access Connector, Managed Identity, and External Locations. |
| **Cloud Infrastructure** | Azure Databricks (Premium SKU) | Serverless compute environment executing multi-task scheduled MLOps DAG jobs. |
| **Infrastructure as Code** | [Terraform](https://www.terraform.io/) (v1.3+) | Automated provisioning of RG, ADLS Gen2, Workspace, Access Credentials, Grants, and Jobs. |
| **Environment & Package Mgmt** | `uv` / `pyproject.toml` | Fast, deterministic Python virtual environment setup. |

---

## 📁 Repository Structure

```
.
├── data/                                  # Local data directory
│   ├── raw/                               # Raw downloaded CSV files
│   └── curated/                           # Cleaned & processed Delta Lake files (.delta)
├── notebooks/                             # Jupyter / Databricks notebooks
│   ├── 01_data_ingestion_and_cleaning.ipynb   # Data download, cleaning, Delta format write
│   └── 02_rfm_feature_engineering_and_ml.ipynb# RFM features, K-Means, MLflow, Seaborn profiling
├── terraform/                             # Infrastructure as Code (IaC)
│   ├── main.tf                            # Core Azure, Unity Catalog & Databricks job resources
│   ├── providers.tf                       # Provider configurations (azurerm, databricks, random)
│   ├── variables.tf                       # Terraform variables (location, environment)
│   └── README.md                          # Terraform deployment guide
├── pyproject.toml                         # Project dependencies and configuration
├── uv.lock                                # Locked dependency tree
└── README.md                              # Main project documentation
```

---

## 📊 Notebook Workflow Details

### 1. Data Ingestion & Data Cleaning (`01_data_ingestion_and_cleaning.ipynb`)
- **Dual Runtime Support**: Auto-detects local vs. Azure Databricks runtime environment (`IS_DATABRICKS`).
- **Data Ingestion**: Downloads the latest E-Commerce dataset directly via `kagglehub` (`mmumairkhattak/e-commerce-orders-dataset-2026-scra`).
- **Data Cleaning & Spark SQL**:
  - Filters out missing or non-positive order amounts (`Order_Amount > 0.0`).
  - Standardizes order timestamps (`Order_Date` -> `Order_Timestamp`) using PySpark SQL `TO_TIMESTAMP`.
  - Maps return status to binary flags (`Returned_Flag`), populates default payment methods, and adds `Ingested_At` metadata.
- **Delta Lake Storage**: Writes cleaned records in optimized **Delta format** with Snappy compression to `ABFSS` storage (`abfss://raw-data@<storage_account>.dfs.core.windows.net/curated/cleaned_orders.delta`) or local `../data/curated/cleaned_orders.delta`.
- **Catalog Integration**: Registers Delta catalog table `default.cleaned_orders` on Databricks runtimes.

### 2. RFM Feature Engineering & ML Pipeline (`02_rfm_feature_engineering_and_ml.ipynb`)
- **RFM Metric Calculation**:
  - **Recency**: Days elapsed since the customer's last purchase relative to the max dataset order date (`DATEDIFF(MAX(Order_Timestamp), MAX(c.Order_Timestamp))`).
  - **Frequency**: Total unique order count per customer (`COUNT(Order_ID)`).
  - **Monetary**: Total aggregate spend per customer (`SUM(Order_Amount)`).
  - **Return Rate**: Customer average product return rate (`AVG(Returned_Flag)`).
- **Feature Normalization & Machine Learning**:
  - Scales feature distributions using `sklearn.preprocessing.StandardScaler`.
  - Fits unsupervised `KMeans` ($K=3$ clusters, `random_state=42`).
  - Evaluates cluster separation using `silhouette_score`.
- **MLflow Experiment Tracking**:
  - Configures experiment path `/Shared/Customer_Segmentation_MLOps`.
  - Logs hyperparameters (`k_clusters=3`, `seed=42`, `algorithm="scikit-learn-kmeans"`), metrics (Silhouette Score = ~0.3479), and registers trained model artifacts natively via `mlflow.sklearn.log_model(sk_model=kmeans, artifact_path="kmeans_rfm_model")`.
- **Profiling & Visualization**:
  - Appends cluster predictions (`cluster_id`) back to the PySpark DataFrame.
  - Profiles cluster metrics (average recency, frequency, monetary spend, return rate) via PySpark SQL queries.
  - Renders customer spend distribution visualizations with Seaborn and Matplotlib.

---

## 🚀 Quickstart Guide

### Prerequisites
- **Python**: `>= 3.11`
- **Package Manager**: [`uv`](https://github.com/astral-sh/uv) (recommended) or standard `pip`
- **Azure CLI**: Logged in via `az login`
- **Terraform CLI**: `>= 1.3.0`

---

### Local Development Setup

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/PedroLiu1999/azure-pyspark-ml-pipeline.git
   cd azure-pyspark-ml-pipeline
   ```

2. **Initialize Environment with `uv`**:
   ```bash
   uv sync
   source .venv/bin/activate
   ```

3. **Run Notebooks Locally**:
   Open and run the notebooks in order:
   - `notebooks/01_data_ingestion_and_cleaning.ipynb`
   - `notebooks/02_rfm_feature_engineering_and_ml.ipynb`

---

### Cloud Infrastructure Deployment (Terraform)

1. **Authenticate with Azure CLI**:
   ```bash
   az login
   ```

2. **Navigate to `terraform/`**:
   ```bash
   cd terraform
   ```

3. **Initialize & Apply Infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Provisioned Cloud Resources**:
   - **Azure Resource Group**: `rg-pyspark-portfolio-dev`
   - **Data Lake Storage Gen2**: `stspark<random>` with container `raw-data` (Hierarchical Namespace enabled)
   - **Databricks Workspace**: Premium SKU (`dbx-portfolio-workspace-dev`)
   - **Unity Catalog Integration**: Databricks Access Connector (Azure Managed Identity), Storage Credentials, External Location, and Grants
   - **Notebook Sync**: Automated upload of notebooks to `/Shared/notebooks/`
   - **Serverless MLOps Job Workflow**: Multi-task DAG workflow (`data_ingestion_task` -> `rfm_ml_training_task`) using Serverless compute (`serverless_ml_env` with `kagglehub` dependency) scheduled daily at 6:00 AM UTC

---

## ⚠️ Solved Gotchas & Technical Insights

| Challenge | Cause | Resolution |
| :--- | :--- | :--- |
| **Azure Provider Timeout** | AzureRM provider attempts to auto-register 50+ resource providers, hanging on restricted subscriptions. | Configured `skip_provider_registration = true` in `providers.tf`. |
| **Databricks SKU Deprecation** | Azure deprecated `standard` SKU for new Databricks workspace creations. | Upgraded `sku = "premium"` in `main.tf`. |
| **Unity Catalog Passwordless Storage** | Manual access keys / SAS tokens introduce security vulnerabilities and credential rotation overhead. | Provisioned `azurerm_databricks_access_connector` with Managed Identity (`Storage Blob Data Contributor`) and configured Unity Catalog `databricks_storage_credential` & `databricks_external_location`. |
| **Notebook Cloud Compatibility** | Local file paths (`../data`) fail on Databricks clusters without DBFS/ADLS mounts. | Introduced dynamic environment detection (`IS_DATABRICKS`), widget parameter retrieval (`STORAGE_ACCOUNT_NAME`), and ABFSS protocol pathing (`abfss://raw-data@<storage>.dfs.core.windows.net`). |
| **Serverless Dependency Provisioning** | Serverless compute nodes lack custom third-party Python packages (`kagglehub`) preinstalled. | Specified `environment` block in `databricks_job` targeting `serverless_ml_env` (version 3) with explicit `kagglehub` pip package dependencies. |
| **Delta Lake Storage Format** | Standard Parquet files lack ACID support and catalog metadata integration. | Saved curated orders as Delta Lake format (`cleaned_orders.delta`) and registered catalog table `default.cleaned_orders`. |

---

## 📄 License

This project is licensed under the MIT License.
