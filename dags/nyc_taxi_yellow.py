from datetime import datetime, timedelta

import requests
from airflow import DAG
from airflow.decorators import task
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.providers.google.cloud.transfers.local_to_gcs import LocalFilesystemToGCSOperator

PROJECT = "nyc-taxi-de-cj"
BUCKET = "nyc-taxi-de-cj-raw"
LOCATION = "europe-west2"
CONN_ID = "google_cloud_default"
BASE_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data"

# Jinja template: Airflow fills this in per run, e.g. "2026-05"
MONTH = "{{ data_interval_start.strftime('%Y-%m') }}"
FILE_NAME = f"yellow_tripdata_{MONTH}.parquet"

default_args = {"retries": 2, "retry_delay": timedelta(minutes=2)}

with DAG(
    dag_id="nyc_taxi_yellow",
    start_date=datetime(2026, 5, 1),
    end_date=datetime(2026, 7, 1),
    schedule="@monthly",
    catchup=True,
    max_active_runs=1,
    default_args=default_args,
    tags=["nyc-taxi", "bigquery"],
) as dag:

    @task
    def download(data_interval_start=None):
        month = data_interval_start.strftime("%Y-%m")
        url = f"{BASE_URL}/yellow_tripdata_{month}.parquet"
        path = f"/opt/airflow/data/yellow_tripdata_{month}.parquet"
        with requests.get(url, stream=True, timeout=60) as r:
            r.raise_for_status()
            with open(path, "wb") as f:
                for chunk in r.iter_content(chunk_size=1024 * 1024):
                    f.write(chunk)
        return path

    upload = LocalFilesystemToGCSOperator(
        task_id="upload_to_gcs",
        src=f"/opt/airflow/data/{FILE_NAME}",
        dst=f"yellow/{FILE_NAME}",
        bucket=BUCKET,
        gcp_conn_id=CONN_ID,
    )

    load_staging = GCSToBigQueryOperator(
        task_id="load_to_staging",
        bucket=BUCKET,
        source_objects=[f"yellow/{FILE_NAME}"],
        destination_project_dataset_table=f"{PROJECT}.raw.yellow_tripdata_staging",
        source_format="PARQUET",
        write_disposition="WRITE_TRUNCATE",
        create_disposition="CREATE_IF_NEEDED",
        location=LOCATION,
        gcp_conn_id=CONN_ID,
    )

    replace_month = BigQueryInsertJobOperator(
        task_id="replace_month_in_raw",
        configuration={
            "query": {
                "query": "{% include 'sql/load_month.sql' %}",
                "useLegacySql": False,
            }
        },
        location=LOCATION,
        gcp_conn_id=CONN_ID,
    )

    rebuild_clean = BigQueryInsertJobOperator(
        task_id="rebuild_clean_trips",
        configuration={
            "query": {
                "query": "{% include 'sql/clean_trips.sql' %}",
                "useLegacySql": False,
            }
        },
        location=LOCATION,
        gcp_conn_id=CONN_ID,
    )

    rebuild_aggregates = BigQueryInsertJobOperator(
        task_id="rebuild_aggregates",
        configuration={
            "query": {
                "query": "{% include 'sql/aggregates.sql' %}",
                "useLegacySql": False,
            }
        },
        location=LOCATION,
        gcp_conn_id=CONN_ID,
    )

    download() >> upload >> load_staging >> replace_month >> rebuild_clean >> rebuild_aggregates