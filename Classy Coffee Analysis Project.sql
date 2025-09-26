-- Creating The Tables

DROP TABLE IF EXISTS sales_coffee;
CREATE TABLE sales_coffee 
(     sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT
)
SELECT COUNT ( * ) FROM sales_coffee

DROP TABLE IF EXISTS products_coffee
CREATE TABLE products_coffee
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
)
SELECT * FROM products_coffee

DROP TABLE IF EXISTS cust_coffee
CREATE TABLE cust_coffee
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT
);
SELECT * FROM cust_coffee

DROP TABLE IF EXISTS city_coffee
CREATE TABLE city_coffee
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);
SELECT * FROM city_coffee

-- Inserted the vaues into the tables through CSV file 

-- Assigning the Foreign Key 

ALTER TABLE cust_coffee
ADD CONSTRAINT fk_city
FOREIGN KEY (city_id)
REFERENCES city_coffee(city_id);

ALTER TABLE sales_coffee
ADD CONSTRAINT fk_products
FOREIGN KEY (product_id)
REFERENCES products_coffee(product_id);

ALTER TABLE sales_coffee
ADD CONSTRAINT fk_customers
FOREIGN KEY (customer_id)
REFERENCES cust_coffee(customer_id);

-- Understanding the dataset so that we can get a Overview of it 

SELECT * FROM city_coffee
SELECT * FROM cust_coffee
SELECT * FROM products_coffee
SELECT * FROM sales_coffee

SELECT MIN(total), MAX(total), AVG(total) FROM sales_coffee;

SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total) FROM sales_coffee;

SELECT STDDEV(total) FROM sales_coffee;

SELECT 
EXTRACT(YEAR FROM sale_date) AS yearly_revenue , 
SUM(total) AS total_sales FROM sales_coffee
GROUP BY yearly_revenue
ORDER BY yearly_revenue 

SELECT 
EXTRACT (YEAR FROM sale_date) AS yearr,
EXTRACT(MONTH FROM sale_date) AS month_wise , SUM(total) AS total_sales
FROM sales_coffee  
GROUP BY 1 , 2
ORDER BY 1,2 

------------- DATA ANALYSIS AND BUSINESS KEY PROBLEMS WITH ANSWERS -------------------------

-- My Analysis & Findings


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT city_name,
       ROUND((population * 0.25) / 1000000,2) AS in_millions, city_rank FROM city_coffee
ORDER BY in_millions DESC


-- Q.2 Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT 
     SUM(total) AS total_revenue FROM sales_coffee
WHERE 
     EXTRACT( YEAR FROM sale_date) = 2023
	 AND 
	 EXTRACT ( quarter FROM sale_date) = 4

SELECT ci.city_name , 
     SUM(total) AS total_revenue FROM sales_coffee AS s
JOIN cust_coffee AS cu
ON cu.customer_id = s.customer_id
JOIN city_coffee as ci
ON ci.city_id = cu.city_id
WHERE 
     EXTRACT( YEAR FROM sale_date) = 2023
	 AND 
	 EXTRACT ( quarter FROM sale_date) = 4
GROUP BY 1 
ORDER BY 2 DESC


-- Q.3 Sales Count for Each Product
-- How many units of each coffee product have been sold?
SELECT p.product_name , COUNT(s.sale_id) FROM products_coffee AS p
LEFT JOIN sales_coffee AS s
ON p.product_id = s.product_id 
GROUP BY 1 
ORDER BY 2 DESC


-- Q.4 Average Sales Amount per City
-- What is the average sales amount per customer in each city?
SELECT ci.city_name , 
     SUM(total) AS total_revenue , 
	 COUNT(DISTINCT cu.customer_id) AS total_customer,
	 ROUND(SUM(total)::numeric / COUNT(DISTINCT cu.customer_id)::numeric,2) AS avg_cust_per_city
	 FROM sales_coffee AS s
JOIN cust_coffee AS cu
ON cu.customer_id = s.customer_id
JOIN city_coffee as ci
ON ci.city_id = cu.city_id
GROUP BY 1 
ORDER BY 2 DESC


-- Q.5 City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)
SELECT city_name, ROUND((population *0.25)/1000000, 2) AS Coffee_consumer
FROM city_coffee

SELECT ci.city_name , 
       COUNT(DISTINCT c.customer_id) AS unique_customer
	   FROM sales_coffee AS s
JOIN cust_coffee AS c
ON s.customer_id = c.customer_id
JOIN city_coffee AS ci
ON ci.city_id = c.city_id
GROUP BY 1


-- Q6 Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
CREATE TEMPORARY TABLE sales_volums AS 
WITH volume_sales AS
(
SELECT ci.city_name , p.product_name, COUNT(s.sale_id) AS total_orders,
DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id)DESC) AS rank 
FROM sales_coffee AS s
JOIN products_coffee AS p
ON p.product_id = s.product_id
JOIN cust_coffee AS c 
ON s.customer_id = c.customer_id
JOIN city_coffee AS ci
ON ci.city_id = c.city_id
GROUP BY 1 , 2
--ORDER BY 1 , 3 DESC
) 
SELECT * FROM volume_sales

SELECT * FROM sales_volums
WHERE rank <= 3


-- Q.7 Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
SELECT ci.city_name ,
	 COUNT(DISTINCT c.customer_id) AS unique_customer
	 FROM cust_coffee AS c
JOIN city_coffee AS ci 
ON ci.city_id = c.city_id
JOIN sales_coffee AS s
ON s.customer_id = c.customer_id  
JOIN products_coffee AS p 
ON p.product_id = s.product_id
WHERE p.product_id IN ( 1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1 


-- Q.8 Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
CREATE TEMPORARY TABLE cityyy AS 
(
	SELECT ci.city_name , 
		 COUNT(DISTINCT cu.customer_id) AS total_customer,
		 ROUND(SUM(total)::numeric / COUNT(DISTINCT cu.customer_id)::numeric,2) AS avg_cust_per_city
		 FROM sales_coffee AS s
	JOIN cust_coffee AS cu
	ON cu.customer_id = s.customer_id
	JOIN city_coffee as ci
	ON ci.city_id = cu.city_id
	GROUP BY 1 
	ORDER BY 2 DESC
);

SELECt * FROM  cityyy

SELECT city_name, estimated_rent FROM city_coffee

SELECT c.city_name , c.estimated_rent, cy.total_customer, cy.avg_cust_per_city,
	ROUND(c.estimated_rent::numeric / cy.total_customer::numeric ,2) AS avg_rent_per_cust
	FROM city_coffee AS c
JOIN cityyy AS cy
ON cy.city_name = c.city_name
ORDER BY 5 DESC


-- Q.9 Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city
CREATE TEMPORARY TABLE monthly_sales  AS
SELECT ci.city_name,
       EXTRACT (year FROM sale_date) AS year, 
	   EXTRACT(month FROM sale_date) AS month,
	   SUM(s.total) AS total_revenue FROM sales_coffee AS s 
JOIN cust_coffee AS c
ON c.customer_id = s.customer_id
JOIN city_coffee AS ci 
On ci.city_id = c.city_id
GROUP BY 1,2,3
ORDER BY ci.city_name, year 

CREATE  TEMPORARY TABLE growth_ratio AS
SELECT city_name, year , month ,
       total_revenue AS current_month_sale,
	   LAG(total_revenue, 1) OVER(PARTITION BY city_name) AS last_month_sale
	   FROM monthly_sales

SELECT g.city_name, g.year, g.month, g.current_month_sale, g.last_month_sale,
       ROUND((g.current_month_sale - g.last_month_sale)::numeric / (last_month_sale ::numeric) * 100,2) AS growth_rate
	   FROM growth_ratio AS g

-- FROM CHAT GPT       
SELECT 
    g.city_name, 
    g.year, 
    g.month, 
    g.current_month_sale, 
    g.last_month_sale,
    ROUND(
        CASE 
            WHEN g.last_month_sale = 0 OR g.last_month_sale IS NULL THEN NULL
            ELSE ((g.current_month_sale - g.last_month_sale) / g.last_month_sale) * 100
        END::numeric, 
        2
    ) AS growth_rate
FROM growth_ratio AS g;


-- Q.10 Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

CREATE TEMPORARY TABLE cite AS 
(
	SELECT ci.city_name , 
		 COUNT(DISTINCT cu.customer_id) AS total_customer,
		 ROUND(SUM(total)::numeric / COUNT(DISTINCT cu.customer_id)::numeric,2) AS avg_cust_per_city
		 FROM sales_coffee AS s
	JOIN cust_coffee AS cu
	ON cu.customer_id = s.customer_id
	JOIN city_coffee as ci
	ON ci.city_id = cu.city_id
	GROUP BY 1 
	ORDER BY 3 DESC
);

SELECt * FROM  cite

SELECT city_name, estimated_rent,
       population * 0.25 AS est_coffee_consumer  FROM city_coffee

SELECT c.city_name ,
       c.estimated_rent AS total_rent , 
	   cy.total_customer,
	   ROUND((c.population * 0.25 / 1000000),3) AS est_coffee_consumer_in_millions,
	   cy.avg_cust_per_city,
	   ROUND(c.estimated_rent::numeric / cy.total_customer::numeric ,2) AS avg_rent_per_cust
	FROM city_coffee AS c
JOIN cite AS cy
ON cy.city_name = c.city_name
ORDER BY 5 DESC

SELECT c.city_name,
	   SUM(sa.total) AS total_revenue,
       c.estimated_rent AS total_rent, 
       cy.total_customer,
       ROUND((c.population * 0.25 / 1000000),3) AS est_coffee_consumer_in_millions,
       cy.avg_cust_per_city,
       ROUND(c.estimated_rent::numeric / cy.total_customer::numeric ,2) AS avg_rent_per_cust
FROM city_coffee AS c
JOIN cite AS cy
ON cy.city_name = c.city_name
JOIN cust_coffee AS cu
ON c.city_id = cu.city_id
JOIN sales_coffee AS sa
ON sa.customer_id = cu.customer_id
GROUP BY c.city_name, c.estimated_rent, c.population, cy.total_customer, cy.avg_cust_per_city
ORDER BY total_revenue DESC;

