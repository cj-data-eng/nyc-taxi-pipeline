
ALTER TABLE `nyc-taxi-de-cj.raw.yellow_tripdata_staging`
  ADD COLUMN IF NOT EXISTS request_source STRING,
  ADD COLUMN IF NOT EXISTS cbd_congestion_fee FLOAT64,
  ADD COLUMN IF NOT EXISTS Airport_fee FLOAT64,
  ADD COLUMN IF NOT EXISTS congestion_surcharge FLOAT64;
BEGIN TRANSACTION;

DELETE FROM `nyc-taxi-de-cj.raw.yellow_tripdata`
WHERE source_month = DATE '{{ data_interval_start.strftime("%Y-%m-01") }}';

INSERT INTO `nyc-taxi-de-cj.raw.yellow_tripdata` (
  VendorID, tpep_pickup_datetime, tpep_dropoff_datetime, passenger_count,
  trip_distance, RatecodeID, store_and_fwd_flag, PULocationID, DOLocationID,
  payment_type, fare_amount, extra, mta_tax, tip_amount, tolls_amount,
  improvement_surcharge, total_amount, congestion_surcharge, Airport_fee,
  cbd_congestion_fee, request_source, source_month
)
SELECT
  CAST(VendorID AS INT64),
  CAST(tpep_pickup_datetime AS TIMESTAMP),
  CAST(tpep_dropoff_datetime AS TIMESTAMP),
  CAST(passenger_count AS INT64),
  CAST(trip_distance AS FLOAT64),
  CAST(RatecodeID AS INT64),
  CAST(store_and_fwd_flag AS STRING),
  CAST(PULocationID AS INT64),
  CAST(DOLocationID AS INT64),
  CAST(payment_type AS INT64),
  CAST(fare_amount AS FLOAT64),
  CAST(extra AS FLOAT64),
  CAST(mta_tax AS FLOAT64),
  CAST(tip_amount AS FLOAT64),
  CAST(tolls_amount AS FLOAT64),
  CAST(improvement_surcharge AS FLOAT64),
  CAST(total_amount AS FLOAT64),
  CAST(congestion_surcharge AS FLOAT64),
  CAST(Airport_fee AS FLOAT64),
  CAST(cbd_congestion_fee AS FLOAT64),
  CAST(request_source AS STRING),
  DATE '{{ data_interval_start.strftime("%Y-%m-01") }}'
FROM `nyc-taxi-de-cj.raw.yellow_tripdata_staging`;

COMMIT TRANSACTION;