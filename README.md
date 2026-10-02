# NYC Taxi Pipeline

Airflow + Docker + BigQuery pipeline for NYC TLC yellow taxi trip data.

## Data quality approach

Raw data is kept as-is in the `raw` dataset. All cleaning happens in SQL into the `analytics` dataset, and every exclusion is documented here.

## Known issues in the raw data (July 2026 file, 3,530,109 rows)

- 46 trips have pickup times outside July 2026 (earliest is 2008-12-30)
- 16,911 trips have fare_amount <= 0
- 128,322 trips have trip_distance = 0
- May 2026 files lack the request_source column; it's stored as NULL for that month.

+----------+---------------+----------+--------------+--------------+
|  total   | outside_month | bad_fare | bad_distance | bad_duration |
+----------+---------------+----------+--------------+--------------+
| 11458193 |            77 |    50908 |       369916 |       270247 |
+----------+---------------+----------+--------------+--------------+


clean_trips is built, with about 10.87 million rows from 11.46 million raw. The cleaning rules removed:

Month	Raw	Clean	Removed
May	4,090,836	3,898,816	192,020 (4.7%)
June	3,837,248	3,632,743	204,505 (5.3%)
July	3,530,109	3,333,849	196,260 (5.6%)

That's about 5% in total, which is a sensible amount for taxi data. Put this table in your README. It backs up the "raw kept as-is, exclusions documented" line with real numbers.