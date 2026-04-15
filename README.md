# Polymarket Analytics Pipeline

## How to run

Execute the next command to initialize your proyect in GCP (Bucket and Bigquery Dataset):

```bash
touch .env 
echo -e "TF_VAR_project_id=PROJECT_ID_HERE\nlocation=LOCATION_HERE\nregion=REGION_HERE" > .env
export $(grep -v '^#' .env | xargs)
cd terraform
terraform init
terraform apply
cd ..
docker compose build
docker compose up -d
docker exec -it airflow_light bash -c "cd /opt/airflow/dbt && dbt docs serve --port 8081 --host 0.0.0.0"
```