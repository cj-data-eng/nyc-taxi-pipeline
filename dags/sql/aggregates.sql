CREATE OR REPLACE TABLE `nyc-taxi-de-cj.analytics.daily_summary` AS
SELECT
  pickup_date,
  COUNT(*) AS trips,
  ROUND(SUM(total_amount), 2) AS total_revenue,
  ROUND(AVG(fare_amount), 2) AS avg_fare,
  ROUND(AVG(trip_distance), 2) AS avg_distance_miles,
  ROUND(AVG(trip_minutes), 1) AS avg_trip_minutes,
  ROUND(SAFE_DIVIDE(SUM(IF(payment_type = 1, tip_amount, 0)), SUM(IF(payment_type = 1, fare_amount, 0))) * 100, 1) AS card_tip_pct
FROM `nyc-taxi-de-cj.analytics.clean_trips`
GROUP BY pickup_date;

CREATE OR REPLACE TABLE `nyc-taxi-de-cj.analytics.zone_summary` AS
SELECT
  pickup_borough,
  pickup_zone,
  COUNT(*) AS trips,
  ROUND(SUM(total_amount), 2) AS total_revenue,
  ROUND(AVG(fare_amount), 2) AS avg_fare,
  ROUND(AVG(trip_distance), 2) AS avg_distance_miles
FROM `nyc-taxi-de-cj.analytics.clean_trips`
GROUP BY pickup_borough, pickup_zone;