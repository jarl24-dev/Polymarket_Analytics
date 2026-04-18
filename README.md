# Polymarket Analytics Pipeline

![Terraform](https://img.shields.io/badge/Terraform-GCP-623CE4?logo=terraform)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)
![Python](https://img.shields.io/badge/Python-3.9-blue?logo=python)
![GCP](https://img.shields.io/badge/-Google%20Cloud%20Platform-4285F4?style=flat&logo=google%20cloud&logoColor=white)
![dbt](https://img.shields.io/badge/dbt-FF8000)

A robust, end-to-end data engineering pipeline designed to ingest, transform, and visualize prediction market data from Polymarket. This project demonstrates modern data stack integration using Infrastructure as Code (IaC), workflow orchestration, and analytics engineering.

## Technologies
* **Cloud:** Google Cloud Platform (GCP), BigQuery, GCS.
* **Infrastructure:** Terraform (IaC).
* **Orchestration:** Apache Airflow (Dockerized).
* **Transformation:** dbt (Data Build Tool) with BigQuery adapter.
* **Languages:** Python (Extraction), SQL (Transformation).
* **Visualization:** Looker Studio.

---

## Problem Description

### The Challenge
Prediction markets like **Polymarket** generate high-velocity data that reflects real-world sentiment and probability. However, for analysts and stakeholders, this data is often difficult to utilize at scale due to:
1.  **Fragmented Source Access:** Raw data must be fetched from external APIs which can be unstable or rate-limited.
2.  **Schema Complexity:** API responses are often deeply nested JSON structures that are not optimized for analytical queries.
3.  **Lack of Historical Consistency:** Without a proper data warehouse strategy, capturing incremental changes and historical trends in market volume or price movements is challenging.

### The Solution
This project solves these issues by implementing a **Medallion Architecture** (Bronze/Silver/Gold) pipeline:

* **Automated Extraction:** A Python-based ingestion engine orchestrated by Airflow fetches data from the Polymarket API and stores it in Google Cloud Storage (Bronze layer) as Parquet files for schema enforcement and storage efficiency.
* **Infrastructure Stability:** Terraform ensures the environment is reproducible and scalable, eliminating "it works on my machine" inconsistencies.
* **Analytical Transformation:** Using **dbt**, the raw data is cleaned, casted, and modeled in BigQuery. This transforms raw JSON-like structures into high-performance, denormalized tables (Gold layer) ready for consumption.
* **Data-Driven Insights:** By connecting the final models to Looker Studio, the project provides a seamless bridge from raw API signals to actionable visual insights, allowing users to track market trends with minimal latency and high reliability.

---

## ☁️ Cloud
The infrastructure is fully developed in the cloud using **Google Cloud Platform (GCP)**. To manage the lifecycle of these resources, **Terraform** is used as the Infrastructure as Code (IaC) tool. The [terraform/](./terraform/) directory contains configurations to provision:
* **Google Cloud Storage (GCS):** Acting as the Data Lake for raw and processed files.
* **BigQuery:** Serving as the Data Warehouse for analytical models.

---

## ⚙️ Data Ingestion & Workflow Orchestration
This is an **end-to-end batch pipeline** orchestrated by **Apache Airflow**. The workflow is defined in a DAG that automates the following steps:
1.  **Extract:** Python script pulls from PredScope API to GCS using [extract_and_upload_parquet](airflow/dags/pipeline.py#L103) task. Data is converted to Parquet format to optimize storage and uploaded to the GCS Bronze layer.
2.  **Load:** Data is moved from the lake into native BigQuery tables using [load_parquet_to_bq](airflow/dags/pipeline.py#L109) task. Data is partitioned by date and clustered by market.
3.  **Transform:** dbt runs models (including full-refresh and incremental logic). Command `dbt build` is executed through [dbt_run_all](airflow/dags/pipeline.py#L128) task.
4.  **Visualize:** Looker Studio consumes the Gold layer models.

---

## 🗄️ Data Warehouse
The Data Warehouse is built on **BigQuery**. To optimize query performance and control costs, the analytical tables are specifically engineered with:
* **Partitioning by Date:** All tables are partitioned by the `date` field. This enables efficient time-series analysis and drastically reduces query costs by allowing "partition pruning" (scanning only the relevant days).
* **Clustering by Market:** Tables are clustered by the `market` column. This optimizes the performance of upstream queries and dashboard filters that frequently isolate or group data by specific prediction markets, ensuring fast response times even as the dataset grows.

---

## 🔄 Transformations
Data transformations are handled using **dbt (Data Build Tool)**, following a professional **Medallion Architecture** to ensure data quality and lineage:
* **Staging Layer (Bronze):** Initial cleaning, renaming, and casting of raw data types into a consistent format.
* **Intermediate Layer (Silver):** Normalization, deduplication logic, and business rule applications to create a "source of truth."
* **Mart Layer (Gold):** Final analytical models optimized for consumption, including aggregated market metrics and performance indicators.

The dbt project is configured to support both `full-refresh` operations for complete historical rebuilds and **incremental strategies** to process only the newest data efficiently.

---

---

## 📊 Dashboard
The pipeline connects to a **Looker Studio Dashboard** that serves as the visual presentation layer for the Gold layer models. The dashboard includes two primary visualizations:

1. **Probability of Outcomes per day:** A time-series line chart that tracks the daily fluctuations in outcome probabilities for selected markets, reflecting shifts in market sentiment.
2. **Total Volume ($) per Category:** A bar chart that aggregates trading volume across different market sectors (Politics, Sports, Crypto, etc.), highlighting where the highest liquidity and user interest are concentrated.

**Live Report:** [View the Polymarket Analytics Dashboard here](https://datastudio.google.com/reporting/cca725be-aaab-4894-9b0b-5a4946c09c7f)

---

## 🚀 Reproducibility
The following instructions ensure the code can be deployed and run on a clean environment:
### 1. Environment Setup
Clone the repository and configure your environment variables:

```bash
touch .env 
echo -e "TF_VAR_project_id=PROJECT_ID_HERE\nTF_VAR_location=LOCATION_HERE\nTF_VAR_region=REGION_HERE" > .env
export $(grep -v '^#' .env | xargs)
```

### 2. Setup GCP credentials
Save your GCP credentials (Service Account) as `keys/keys.json`

### 3. Infrastructure Deployment
Provision the required GCP resources using Terraform:

```bash
cd terraform
terraform init
terraform apply
cd ..
```

### 4. Orchestration & Deployment
Build and launch the Airflow stack:

```bash
docker compose build
docker compose up -d
```

The DAG is configured to run every 10 minutes to ensure near real-time data availability.

If you want to check dbt report, execute the next command:

```bash
docker exec -it airflow_light bash -c "cd /opt/airflow/dbt && dbt docs serve --port 8081 --host 0.0.0.0"
```
