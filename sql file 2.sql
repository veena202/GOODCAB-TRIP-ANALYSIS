/* Business Request - 2: Monthly City-Level Trips Target Performance Report
Generate a report that evaluates the target performance for trips at the monthly and city level. 
For each city and month, compare the actual total trips with the target trips and categorise the performance as follows:
 	If actual trips are greater than target trips, mark it as "Above Target".
 	If actual trips are less than or equal to target trips, mark it as "Below Target".
Additionally, calculate the % difference between actual and target trips to quantify the performance gap.*/

use trips_db;
USE  targets_db;
SELECT
    c.city_name,
    DATE_FORMAT(t.month, '%Y-%m') AS month, 
    count(f.trip_id) AS actual_total_trips,
    t.total_target_trips,
    CASE 
        WHEN SUM(f.trip_id) > t.total_target_trips THEN 'Above Target'
        ELSE 'Below Target'
    END AS performance,
    ROUND((count(f.trip_id) - t.total_target_trips) * 100.0 / t.total_target_trips, 2) AS performance_gap_percentage
FROM 
    fact_trips f
JOIN 
    dim_city c 
    ON f.city_id = c.city_id
JOIN 
   targets_db.monthly_target_trips t 
    ON f.city_id = t.city_id AND DATE_FORMAT(f.date, '%Y-%m') = DATE_FORMAT(t.month, '%Y-%m')
GROUP BY 
    c.city_name, t.month, t.total_target_trips;

