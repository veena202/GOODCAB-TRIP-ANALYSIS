/*Bussiness problem 1 city level fare and trip summmary report*/


SELECT 
    dc.city_name,
    COUNT(ft.trip_id) AS total_trips,
    AVG(ft.fare_amount / ft.distance_travelled_km) AS avg_fare_per_km,
    AVG(ft.fare_amount) AS avg_fare_per_trip,
    ROUND((COUNT(ft.trip_id) * 100.0 / (SELECT COUNT(*) FROM fact_trips)), 2) AS percent_contribution
FROM 
    dim_city dc
    LEFT JOIN fact_passenger_summary fps ON dc.city_id = fps.city_id
    LEFT JOIN fact_trips ft ON dc.city_id = ft.city_id
GROUP BY 
    dc.city_name
ORDER BY
    total_trips DESC;
    
    