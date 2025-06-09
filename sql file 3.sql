/*Business Request - 3: City-Level Repeat Passenger Trip Frequency Report
Generate a report that shows the percentage distribution of repeat passengers by the number of trips they have taken in each city. Calculate the percentage of repeat passengers who took 2 trips, 3 trips, and so on, up to 10 trips.
Each column should represent a trip count category, displaying the percentage of repeat passengers who fall into that category out of the total repeat passengers for that city.
This report will help identify cities with high repeat trip frequency, which can indicate strong customer loyalty or frequent usage patterns.
• Fields: city name, 2-Trips, 3-Trips, 4-Trips, 5-Trips, 6-Trips, 7-Trips, 8-Trips, 9-Trips, 10-Trips
*/
SELECT 
    c.city_name,
    ROUND(SUM(CASE WHEN r.trip_count = '2-Trips' THEN r.repeat_passenger_count ELSE 0 END) * 100.0 / SUM(r.repeat_passenger_count), 2) AS "2-Trips",
    ROUND(SUM(CASE WHEN r.trip_count = '3-Trips' THEN r.repeat_passenger_count ELSE 0 END) * 100.0 / SUM(r.repeat_passenger_count), 2) AS "3-Trips",
    ROUND(SUM(CASE WHEN r.trip_count = '4-Trips' THEN r.repeat_passenger_count ELSE 0 END) * 100.0 / SUM(r.repeat_passenger_count), 2) AS "4-Trips",
    ROUND(SUM(CASE WHEN r.trip_count = '5-Trips' THEN r.repeat_passenger_count ELSE 0 END) * 100.0 / SUM(r.repeat_passenger_count), 2) AS "5-Trips",
    ROUND(SUM(CASE WHEN r.trip_count = '6-Trips' THEN r.repeat_passenger_count ELSE 0 END) * 100.0 / SUM(r.repeat_passenger_count), 2) AS "6-Trips",
    ROUND(SUM(CASE WHEN r.trip_count = '7-Trips' THEN r.repeat_passenger_count ELSE 0 END) * 100.0 / SUM(r.repeat_passenger_count), 2) AS "7-Trips",
    ROUND(SUM(CASE WHEN r.trip_count = '8-Trips' THEN r.repeat_passenger_count ELSE 0 END) * 100.0 / SUM(r.repeat_passenger_count), 2) AS "8-Trips",
    ROUND(SUM(CASE WHEN r.trip_count = '9-Trips' THEN r.repeat_passenger_count ELSE 0 END) * 100.0 / SUM(r.repeat_passenger_count), 2) AS "9-Trips",
    ROUND(SUM(CASE WHEN r.trip_count = '10-Trips' THEN r.repeat_passenger_count ELSE 0 END) * 100.0 / SUM(r.repeat_passenger_count), 2) AS "10-Trips"
FROM 
    dim_repeat_trip_distribution r
JOIN 
    dim_city c
    ON c.city_id = r.city_id
GROUP BY 
    c.city_name;
    
/*Business Request - 4: Identify Cities with Highest and Lowest Total New Passengers
Generate a report that calculates the total new passengers for each city and ranks them based on this value. Identify the top 3 cities with the highest number of new passengers as well as the bottom 3 cities with the lowest number of new passengers, categorising them as "Top 3" or "Bottom 3" accordingly.
FieldS
 	city name
 	total new_passengers
 	city category ("Top 3" or "Bottom 3")
*/
use trips_db;

SELECT 
    c.city_name,
    SUM(p.new_passengers) AS total_new_passengers,
    CASE
        WHEN RANK() OVER (ORDER BY SUM(p.new_passengers) DESC) <= 3 THEN 'Top 3'
        WHEN RANK() OVER (ORDER BY SUM(p.new_passengers) DESC) > (SELECT COUNT(DISTINCT c.city_id) - 3 FROM dim_city c JOIN fact_passenger_summary p ON c.city_id = p.city_id) THEN 'Bottom 3'
        ELSE 'No Category'
    END AS city_category,
    RANK() OVER (ORDER BY SUM(p.new_passengers) DESC) AS rank_of_city
FROM 
    dim_city c
JOIN 
    fact_passenger_summary p ON c.city_id = p.city_id
GROUP BY 
    c.city_id, c.city_name
ORDER BY 
    total_new_passengers DESC;


/*Business Request - 5: Identify Month with Highest Revenue for Each City
Generate a report that identifies the month with the highest revenue for each city.
 For each city, display the month_name, the revenue amount for that month, 
 and the percentage contribution of that month's revenue to the city's total revenue.
Fields- city name   highest revenue_month   revenue   percentage contribution ( 0/0)
*/
use trips_db;
WITH CityMonthlyRevenue AS (
    SELECT 
        c.city_name,
        MONTHNAME(f.date) AS revenue_month,
        SUM(f.fare_amount) AS monthly_revenue
    FROM 
        dim_city c
    JOIN 
        fact_trips f ON c.city_id = f.city_id
    GROUP BY 
        c.city_name, MONTHNAME(f.date)
),
CityTotalRevenue AS (
    SELECT 
        city_name,
        SUM(monthly_revenue) AS total_revenue
    FROM 
        CityMonthlyRevenue
    GROUP BY 
        city_name
),
HighestRevenueMonth AS (
    SELECT 
        cmr.city_name,
        cmr.revenue_month AS highest_revenue_month,
        cmr.monthly_revenue AS highest_revenue
    FROM 
        CityMonthlyRevenue cmr
    JOIN 
        (SELECT 
            city_name,
            MAX(monthly_revenue) AS highest_revenue
         FROM 
            CityMonthlyRevenue
         GROUP BY 
            city_name) max_revenue
    ON cmr.city_name = max_revenue.city_name AND cmr.monthly_revenue = max_revenue.highest_revenue
)
SELECT 
    hrm.city_name,
    hrm.highest_revenue_month,
    hrm.highest_revenue,
    ROUND((hrm.highest_revenue / ctr.total_revenue) * 100, 3) AS percentage_contribution
FROM 
    HighestRevenueMonth hrm
JOIN 
    CityTotalRevenue ctr ON hrm.city_name = ctr.city_name
ORDER BY 
    hrm.city_name;




/*  Business Request - 6: Repeat Passenger Rate Analysis
Generate a report that calculates two metrics:
1.	Monthly Repeat Passenger Rate: Calculate the repeat passenger rate for each city and month by comparing the number of repeat passengers to the total passengers.
2.	City-wide Repeat Passenger Rate: Calculate the overall repeat passenger rate for each city, considering all passengers across months.
These metrics will provide insights into monthly repeat trends as well as the overall repeat behaviour for each city.
Fields:
  city name   month   total_passengers   repeat_passengers   monthly_repeat passenger rate ( 0/0): Repeat passenger rate at the city and month level   city repeat_passenger rate ( 0/0): Overall repeat passenger rate for each city, aggregated across months
*/
use trips_db
WITH CityMonthlyData AS (
    SELECT 
        c.city_name,
        MONTHNAME(p.month) AS month,
        SUM(p.total_passengers) AS total_passengers,
        SUM(p.repeat_passengers) AS repeat_passengers,
        ROUND(SUM(p.repeat_passengers) / SUM(p.total_passengers) * 100, 2) AS monthly_repeat_passenger_rate
    FROM 
        dim_city c
    JOIN 
        fact_passenger_summary p
    ON 
        c.city_id = p.city_id
    GROUP BY 
        c.city_name, MONTHNAME(p.month)
),
CityOverallData AS (
    SELECT 
        c.city_name,
        SUM(p.total_passengers) AS total_passengers,
        SUM(p.repeat_passengers) AS repeat_passengers,
        ROUND(SUM(p.repeat_passengers) / SUM(p.total_passengers) * 100, 2) AS city_repeat_passenger_rate
    FROM 
        dim_city c
    JOIN 
        fact_passenger_summary p
    ON 
        c.city_id = p.city_id
    GROUP BY 
        c.city_name
)
SELECT 
    m.city_name,
    m.month,
    m.total_passengers,
    m.repeat_passengers,
    m.monthly_repeat_passenger_rate,
    o.city_repeat_passenger_rate
FROM 
    CityMonthlyData m
JOIN 
    CityOverallData  o
ON 
    m.city_name = o.city_name
ORDER BY 
    m.city_name, m.month;




