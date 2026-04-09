from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.hooks.gcs import GCSHook
from airflow.providers.google.cloud.operators.bigquery import BigQueryCreateExternalTableOperator
from datetime import datetime, timedelta
import urllib.request
import json
import os
import pandas as pd
import io

PROJECT_ID = os.getenv("TF_VAR_project_id")
BUCKET_NAME = f"{PROJECT_ID}-polymarket-analytics" 

DATASET_NAME = "polymarket_staging"
TABLE_NAME = "markets_external"

def extract_from_api_to_gcs(**kwargs):
    url = "https://predscope.com/api/markets.json"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
    }
    
    try:
        # 1. Petición a la API
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read())
        
        # 2. Convertir la lista de mercados a DataFrame de Pandas
        # Asumimos que la API devuelve {"markets": [...]}
        df = pd.DataFrame(data.get("markets", []))
        
        if df.empty:
            print("No se encontraron datos en 'markets'.")
            return
        
        df['extraction_timestamp'] = pd.to_datetime(kwargs['logical_date'])

        # 3. Transformar el DataFrame a formato Parquet en memoria (Buffer)
        parquet_buffer = io.BytesIO()
        df.to_parquet(
            parquet_buffer, 
            index=False, 
            engine='pyarrow',
            coerce_timestamps='us',
            allow_truncated_timestamps=True 
        )
        
        # 4. Usamos el GCSHook
        gcs_hook = GCSHook(gcp_conn_id="google_cloud_default")

        logical_date = kwargs['logical_date'] # Esta es la fecha real de la ejecución
        ts_nodash = logical_date.strftime('%Y%m%dT%H%M%S')
        year = logical_date.strftime('%Y')
        month = logical_date.strftime('%m')
        day = logical_date.strftime('%d')

        # Nueva ruta con formato key=value
        partition_path = f"year={year}/month={month}/day={day}"
        
        # Ruta organizada: raw_parquet/año/mes/dia/archivo.parquet
        file_name = f"polymarket_raw_{ts_nodash}.parquet"
        storage_path = f"raw_parquet/{partition_path}/{file_name}"
        
        # 5. Subida de los bytes del buffer
        gcs_hook.upload(
            bucket_name=BUCKET_NAME,
            object_name=storage_path,
            data=parquet_buffer.getvalue(),
            mime_type='application/octet-stream' # Mime type estándar para binarios/parquet
        )
        print(f"EXITO: {len(df)} registros subidos en Parquet a gs://{BUCKET_NAME}/{storage_path}")

    except Exception as e:
        print(f"ERROR en la extracción: {e}")
        raise

# Configuración del DAG
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=2),
}

with DAG(
    dag_id="01_predscope_api_to_gcs_parquet",
    default_args=default_args,
    description="Extrae datos de PredScope en formato Parquet cada 10 min",
    schedule_interval="*/10 * * * *",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    is_paused_upon_creation=False,
    tags=['polymarket', 'parquet'],
) as dag:

    task_extract = PythonOperator(
        task_id="extract_and_upload_parquet",
        python_callable=extract_from_api_to_gcs,
        provide_context=True
    )

    task_create_external_table = BigQueryCreateExternalTableOperator(
        task_id="create_external_table",
        table_resource={
            "tableReference": {
                "projectId": PROJECT_ID,
                "datasetId": DATASET_NAME,
                "tableId": TABLE_NAME,
            },
            "externalDataConfiguration": {
                "sourceFormat": "PARQUET",
                "sourceUris": [f"gs://{BUCKET_NAME}/raw_parquet/*"],
                "hivePartitioningOptions": {
                    "mode": "AUTO",
                    "sourceUriPrefix": f"gs://{BUCKET_NAME}/raw_parquet/",
                    "requirePartitionFilter": False,
                },
                "autodetect": True,
            },
        },
        gcp_conn_id="google_cloud_default",
    )

    task_extract >> task_create_external_table