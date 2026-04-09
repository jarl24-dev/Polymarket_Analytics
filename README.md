# Polymarket Analytics Pipeline

## How to run

Execute the next command to initialize your proyect in GCP (Bucket and Bigquery Dataset):

```bash
touch .env && echo 'TF_VAR_project_id=PROJECT_ID_HERE' > .env
export $(grep -v '^#' .env | xargs)
cd terraform
terraform init
terraform apply
cd ..
docker compose up -d
```