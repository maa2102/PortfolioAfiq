-- 1. Observe datasets
SELECT * 
FROM brands_sport;

SELECT * 
FROM finance;

SELECT * 
FROM reviews_brands;

SELECT * 
FROM info_brands;

SELECT * 
FROM traffic_brands;

-- 2. Create new table 
CREATE TABLE sports_items
LIKE brands_sport;

INSERT sports_items
SELECT *
FROM brands_sport;

CREATE TABLE sports_sales
LIKE finance;

INSERT sports_sales
SELECT *
FROM finance;

CREATE TABLE sports_info
LIKE info_brands;

INSERT sports_info
SELECT *
FROM info_brands;

CREATE TABLE sports_reviews
LIKE reviews_brands;

INSERT sports_reviews
SELECT *
FROM reviews_brands;

CREATE TABLE sports_traffic
LIKE traffic_brands;

INSERT sports_traffic
SELECT *
FROM traffic_brands;

-- 3. Data Cleaning

-- Duplicated data
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY product_id, brand) AS row_num
FROM sports_items
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Missing Values
SELECT * 
FROM sports_items
WHERE brand is null
OR brand = '';

-- Fill missing values with null
UPDATE sports_items
SET brand = null
WHERE brand = '';

SELECT *
FROM sports_sales
WHERE revenue = '';

-- Drop rows with missing values in revenue
DELETE 
FROM sports_sales
WHERE revenue = '';

SELECT * 
FROM sports_reviews
WHERE rating = ''
AND reviews = '';

-- Drop rows with missing values in rating and reviews
DELETE 
FROM sports_reviews
WHERE rating = ''
AND reviews = '';

-- Drop unneed columns
ALTER TABLE sports_info
DROP COLUMN description;

-- 4. Data Analysis
-- Count number of items
SELECT COUNT(product_id)
FROM sports_items
WHERE brand IS NOT NULL;

-- Get total items, average listing price, maximum and minimum sale price and maximum revenue for each brand
SELECT brand, COUNT(it.product_id) total_item, 
AVG(CAST(listing_price AS decimal(5,1))) avg_price,
MAX(sale_price) max_sale_price,
MIN(sale_price) min_sale_price,
MAX(revenue) max_revenue
FROM sports_items it
JOIN sports_sales s ON it.product_id = s.product_id
WHERE listing_price > 0 AND brand IS NOT NULL
GROUP BY brand; 

-- Top 10 items generate most revenue for Adidas
SELECT brand, 
CAST(revenue AS FLOAT) revenue_float, 
product_name, 
CAST(rating AS FLOAT) rating_float
FROM sports_items it
JOIN sports_sales s ON it.product_id = s.product_id
JOIN sports_info i ON it.product_id = i.product_id
JOIN sports_reviews r ON it.product_id = r.product_id
WHERE brand = 'Adidas'
ORDER BY revenue_float DESC
LIMIT 10;

-- Top 10 items generate most revenue for Nike
SELECT brand, 
CAST(revenue AS FLOAT) revenue_float, 
product_name, 
CAST(rating AS FLOAT) rating_float
FROM sports_items it
JOIN sports_sales s ON it.product_id = s.product_id
JOIN sports_info i ON it.product_id = i.product_id
JOIN sports_reviews r ON it.product_id = r.product_id
WHERE brand = 'Nike'
ORDER BY revenue_float DESC
LIMIT 10;

-- Count number of Adidas items that generate 0 revenue
WITH duplicate_cte AS
(
SELECT brand, 
CAST(revenue AS FLOAT) revenue_float, 
product_name, 
CAST(rating AS FLOAT) rating_float
FROM sports_items it
JOIN sports_sales s ON it.product_id = s.product_id
JOIN sports_info i ON it.product_id = i.product_id
JOIN sports_reviews r ON it.product_id = r.product_id
WHERE brand = 'Adidas'
)
SELECT COUNT(brand)
FROM duplicate_cte
WHERE revenue_float = 0;

-- List of Adidas items that generate 0 revenue
WITH duplicate_cte AS
(
SELECT Brand,
CAST(revenue AS FLOAT) revenue_float, 
it.product_id, 
CAST(rating AS FLOAT) rating_float
FROM sports_items it
JOIN sports_sales s ON it.product_id = s.product_id
JOIN sports_info i ON it.product_id = i.product_id
JOIN sports_reviews r ON it.product_id = r.product_id
WHERE brand = 'Adidas'
)
SELECT *
FROM duplicate_cte
WHERE revenue_float = 0;

-- Count number of Nike items that generate 0 revenue
WITH duplicate_cte AS
(
SELECT it.product_id,
brand, 
CAST(revenue AS FLOAT) revenue_float, 
product_name, 
CAST(rating AS FLOAT) rating_float
FROM sports_items it
JOIN sports_sales s ON it.product_id = s.product_id
JOIN sports_info i ON it.product_id = i.product_id
JOIN sports_reviews r ON it.product_id = r.product_id
WHERE brand = 'Nike'
)
SELECT COUNT(product_id)
FROM duplicate_cte
WHERE revenue_float = 0;

-- List of Nike items that generate 0 revenue
WITH duplicate_cte AS
(
SELECT Brand,
CAST(revenue AS FLOAT) revenue_float, 
it.product_id, 
CAST(rating AS FLOAT) rating_float
FROM sports_items it
JOIN sports_sales s ON it.product_id = s.product_id
JOIN sports_info i ON it.product_id = i.product_id
JOIN sports_reviews r ON it.product_id = r.product_id
WHERE brand = 'Nike'
)
SELECT *
FROM duplicate_cte
WHERE revenue_float = 0;

-- Listing price by brand
SELECT brand,
CAST(listing_price AS FLOAT) listing_price,
COUNT(*) count
FROM sports_sales s
INNER JOIN sports_items it ON s.product_id = it.product_id
WHERE listing_price > 0
GROUP BY brand, listing_price
ORDER BY brand, listing_price ASC;

-- Total revenue by brands and price category
SELECT brand, 
COUNT(*) AS count, 
SUM(CAST(revenue AS decimal(5,2))) AS total_revenue,
       CASE 
           WHEN listing_price < 42 THEN 'Budget'
           WHEN listing_price >= 42 AND listing_price < 74 THEN 'Average'
           WHEN listing_price >= 74 AND listing_price < 129 THEN 'Expensive'
           ELSE 'Elite' 
       END AS price_category
FROM sports_sales s
INNER JOIN sports_items it ON s.product_id = it.product_id
WHERE brand IS NOT NULL
GROUP BY brand, price_category
ORDER BY total_revenue DESC;

-- Monthly review counts by brands
SELECT brand, 
       MONTH(`last_visited`) AS visited_month,
       COUNT(reviews) AS num_reviews
FROM sports_reviews r
INNER JOIN sports_traffic t ON r.product_id = t.product_id
INNER JOIN sports_items it ON r.product_id = it.product_id
GROUP BY brand, visited_month
HAVING brand IS NOT NULL
AND visited_month IS NOT NULL
ORDER BY brand, visited_month;

-- Yearly review counts by brands
SELECT brand, 
       YEAR(`last_visited`) AS visited_year,
       COUNT(reviews) AS num_reviews
FROM sports_reviews r
INNER JOIN sports_traffic t ON r.product_id = t.product_id
INNER JOIN sports_items it ON r.product_id = it.product_id
GROUP BY brand, visited_year
HAVING brand IS NOT NULL
AND visited_year IS NOT NULL
ORDER BY brand, visited_year;
