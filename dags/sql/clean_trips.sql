CREATE OR REPLACE TABLE `nyc-taxi-de-cj.analytics.clean_trips`
PARTITION BY pickup_date
CLUSTER BY pickup_borough
AS
SELECT
  t.source_month,
  DATE(t.tpep_pickup_datetime) AS pickup_date,
  t.tpep_pickup_datetime AS pickup_at,
  t.tpep_dropoff_datetime AS dropoff_at,
  TIMESTAMP_DIFF(t.tpep_dropoff_datetime, t.tpep_pickup_datetime, MINUTE) AS trip_minutes,
  t.passenger_count,
  t.trip_distance,
  t.fare_amount,
  t.tip_amount,
  t.total_amount,
  t.payment_type,
  t.PULocationID,
  pz.Borough AS pickup_borough,
  pz.Zone AS pickup_zone,
  t.DOLocationID,
  dz.Borough AS dropoff_borough,
  dz.Zone AS dropoff_zone
FROM `nyc-taxi-de-cj.raw.yellow_tripdata` AS t
LEFT JOIN `nyc-taxi-de-cj.raw.taxi_zones` AS pz ON t.PULocationID = pz.LocationID
LEFT JOIN `nyc-taxi-de-cj.raw.taxi_zones` AS dz ON t.DOLocationID = dz.LocationID
WHERE t.tpep_pickup_datetime >= TIMESTAMP(t.source_month)
  AND t.tpep_pickup_datetime < TIMESTAMP(DATE_ADD(t.source_month, INTERVAL 1 MONTH))
  AND t.fare_amount > 0
  AND t.trip_distance > 0
  AND t.trip_distance < 100
  AND TIMESTAMP_DIFF(t.tpep_dropoff_datetime, t.tpep_pickup_datetime, MINUTE) BETWEEN 1 AND 180;