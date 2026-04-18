FROM apache/airflow:2.10.2-python3.9

USER root

RUN apt-get update && apt-get install -y git && apt-get clean

RUN chmod -R 777 /opt/airflow/dbt /opt/airflow/keys 

USER airflow

COPY requirements.txt /opt/airflow/requirements.txt

RUN pip install --no-cache-dir -r /opt/airflow/requirements.txt

ENV PATH="${PATH}:/home/airflow/.local/bin"

