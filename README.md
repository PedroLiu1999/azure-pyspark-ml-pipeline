# 🚀 Azure PySpark & Databricks MLOps Pipeline: E-Commerce Customer Segmentation

[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![PySpark](https://img.shields.io/badge/PySpark-3.5.0-E25A1C?style=flat&logo=apachespark&logoColor=white)](https://spark.apache.org/docs/latest/api/python/)
[![Azure](https://img.shields.io/badge/Azure-Databricks%20%26%20ADLS%20Gen2-0089D6?style=flat&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![Terraform](https://img.shields.io/badge/Terraform-1.3+-844FBA?style=flat&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![MLflow](https://img.shields.io/badge/MLflow-Tracking-0194E2?style=flat&logo=mlflow&logoColor=white)](https://mlflow.org/)

An end-to-end, production-grade **Machine Learning & MLOps Pipeline** built with **PySpark**, **Azure Databricks**, **Azure Data Lake Storage (ADLS Gen2)**, and **Terraform**.

This project processes raw e-commerce order transactions, performs automated data validation and cleaning, constructs **RFM (Recency, Frequency, Monetary)** features using PySpark SQL & Window functions, trains an unsupervised **K-Means Clustering model** for customer segmentation with **MLflow** experiment tracking, and deploys the entire workflow via **Terraform Infrastructure as Code (IaC)** as a scheduled Databricks MLOps job.

---

## 📐 Architecture Overview

```
                                      ┌─────────────────────────────────────────────────────────┐
                                      │                      AZURE CLOUD                        │
                                      │                                                         │
 ┌──────────────────────────┐         │  ┌───────────────────────┐   ┌───────────────────────┐  │
 │  KaggleHub E-Commerce    │         │  │ Azure Data Lake (ADLS)│   │  Databricks Workspace │  │
 │  Dataset (Raw Ingestion) │───────► │  │  Container: raw-data  │──►│  (Premium SKU)        │  │
 └──────────────────────────┘         │  └───────────────────────┘   └───────────┬───────────┘  │
                                      │                                          │              │
                                      │  ┌───────────────────────────────────────▼───────────┐  │
                                      │  │ Single-Node PySpark ML Cluster                    │  │
                                      │  │ (Runtime: 14.3.x-cpu-ml-scala2.12 / D4s_v3)      │  │
                                      │  └───────────────────────┬───────────────────────────┘  │
                                      │                          │                              │
                                      │  ┌───────────────────────▼───────────────────────────┐  │
                                      │  │ Automated MLOps Pipeline Job (Multi-task DAG)     │  │
                                      │  │                                                   │  │
                                      │  │  ┌─────────────────────────────────────────────┐  │  │
                                      │  │  │ Task 1: 01_data_ingestion_and_cleaning    │  │  │
                                      │  │  └──────────────────────┬──────────────────────┘  │  │
                                      │  │                         │                         │  │
                                      │  │  ┌──────────────────────▼──────────────────────┐  │  │
                                      │  │  │ Task 2: 02_rfm_feature_engineering_and_ml │  │  │
                                      │  │  └─────────────────────────────────────────────┘  │  │
                                      │  └───────────────────────────────────────────────────┘  │
                                      └─────────────────────────────────────────────────────────┘
```

---

## 🧰 Technology Stack

| Component | Technology | Purpose |
| :--- | :--- | :--- |
| **Data Processing** | [PySpark SQL & DataFrames](https://spark.apache.org/docs/latest/api/python/) | Distributed data ingestion, schema enforcement, filtering, and cleaning. |
| **Feature Engineering** | PySpark ML (`VectorAssembler`, `StandardScaler`) | RFM aggregation, feature transformations, and feature scaling. |
| **Machine Learning** | PySpark ML (`KMeans`) & MLflow | Unsupervised customer segmentation & experiment metric tracking. |
| **Cloud Infrastructure** | Azure Databricks & ADLS Gen2 | Scalable Spark compute cluster & hierarchical Data Lake storage. |
| **Infrastructure as Code** | [Terraform](https://www.terraform.io/) | Automated provisioning of RG, ADLS Gen2, Databricks Workspace, Cluster, and Jobs. |
| **Environment & Package Mgmt** | `uv` / `pyproject.toml` | Fast, deterministic Python virtual environment setup. |

---

## 📁 Repository Structure

```
.
├── data/                                  # Local data directory
│   ├── raw/                               # Raw downloaded CSV files
│   └── curated/                           # Cleaned & processed Parquet files
├── notebooks/                             # Jupyter / Databricks notebooks
│   ├── 01_data_ingestion_and_cleaning.ipynb   # Ingestion, validation, cleaning
│   └── 02_rfm_feature_engineering_and_ml.ipynb# RFM calculation, K-Means & MLflow
├── terraform/                             # Infrastructure as Code (IaC)
│   ├── main.tf                            # Core Azure & Databricks resources
│   ├── providers.tf                       # Provider configurations (azurerm, databricks)
│   ├── variables.tf                       # Terraform variables (location, environment)
│   └── README.md                          # Terraform deployment guide
├── docs/                                  # Project documentation
├── pyproject.toml                         # Project dependencies and configuration
├── uv.lock                                # Locked dependency tree
└── README.md                              # Main project documentation
```

---

## 📊 Notebook Workflow Details

### 1. Data Ingestion & Data Cleaning (`01_data_ingestion_and_cleaning.ipynb`)
- **Dual Runtime Support**: Auto-detects local vs. Azure Databricks runtime environment (`IS_DATABRICKS`).
- **Data Ingestion**: Downloads the latest E-Commerce dataset directly from KaggleHub (`mmumairkhattak/e-commerce-orders-dataset-2026-scra`).
- **Data Cleaning & Spark SQL**:
  - Filters out missing customer IDs (`Customer_ID IS NOT NULL`).
  - Filters out invalid/negative unit prices and order quantities.
  - Standardizes order timestamps and converts price fields to numeric types.
- **Data Lake Storage**: Writes cleaned records in optimized **Parquet format** to `ABFSS` storage (`abfss://raw-data@<storage_account>.dfs.core.windows.net/curated/cleaned_orders.parquet`) or local `../data/curated/`.

### 2. RFM Feature Engineering & ML Pipeline (`02_rfm_feature_engineering_and_ml.ipynb`)
- **RFM Metric Calculation**:
  - **Recency**: Days since last purchase relative to the max order date.
  - **Frequency**: Total unique order count per customer.
  - **Monetary**: Total revenue generated per customer.
- **Feature Pipeline**:
  - `VectorAssembler`: Combines `[recency, frequency, monetary]` into a feature vector.
  - `StandardScaler`: Normalizes feature distributions to zero mean and unit variance.
- **K-Means Clustering**:
  - Fits PySpark ML `KMeans` ($K=4$ clusters).
  - Evaluates cluster quality using `ClusteringEvaluator` (Silhouette Score).
- **MLflow Integration**:
  - Logs parameters ($K$, seed), metrics (Silhouette Score), and model outputs to MLflow.
- **Export**: Drops intermediate vector columns to avoid serialization issues and writes final customer segments to Parquet.

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
   - **Data Lake Storage Gen2**: `stspark<random>` with container `raw-data`
   - **Databricks Workspace**: Premium SKU (`dbx-portfolio-workspace-dev`)
   - **Single-Node ML Compute**: `Standard_D4s_v3` (14.3.x LTS ML runtime, 4 vCPUs)
   - **Notebook Deployment**: Automated sync of notebooks to `/Shared/notebooks/`
   - **MLOps Job Pipeline**: Multi-task DAG workflow scheduled daily at 6:00 AM UTC

---

## ⚠️ Solved Gotchas & Technical Insights

| Challenge | Cause | Resolution |
| :--- | :--- | :--- |
| **Azure Provider Timeout** | AzureRM provider attempts to auto-register 50+ resource providers, hanging on restricted subscriptions. | Configured `skip_provider_registration = true` in `providers.tf`. |
| **Databricks SKU Deprecation** | Azure deprecated `standard` SKU for new Databricks workspace creations. | Upgraded `sku = "premium"` in `main.tf`. |
| **vCPU Quota Exceeded** | Free/Student subscriptions limit regional vCPUs (e.g. 6 total). Omitted `num_workers` caused multi-node driver+worker allocation (8 vCPUs). | Added `num_workers = 0` explicitly to enforce a single-node cluster (4 vCPUs total). |
| **Notebook Cloud Compatibility** | Local file paths (`../data`) fail on Databricks clusters without DBFS/ADLS mount. | Introduced dynamic environment detection (`IS_DATABRICKS`) and ABFSS protocol pathing (`abfss://raw-data@<storage>.dfs.core.windows.net`). |
| **Parquet Write Failure** | PySpark ML `Vector` types (`raw_features`, `scaled_features`) are incompatible with standard Parquet output writers. | Dropped vector columns via `.drop("raw_features", "scaled_features")` prior to DataFrame serialization. |

---

## 📄 License

This project is licensed under the MIT License.
