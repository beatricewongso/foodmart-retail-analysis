-- quick table and column check
/* 
SELECT 
    TABLE_NAME, 
    COLUMN_NAME, 
    DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'public'
ORDER BY TABLE_NAME, ORDINAL_POSITION
*/

WITH sold_kpi AS (
	SELECT 
		ROUND(SUM(quantity*product_retail_price)::INT,0) AS total_revenue,
		ROUND(SUM(quantity*product_cost)::INT,0) AS total_cost,
		(SUM(quantity*product_retail_price)-SUM(quantity*product_cost))::INT AS total_profit,
		SUM(quantity) AS total_quantity_sold,
		COUNT(DISTINCT c.customer_id) AS total_buying_customers,
		COUNT(DISTINCT b.product_id) AS total_unique_products_sold,
		COUNT(DISTINCT b.product_brand) AS total_unique_brands_sold,
		COUNT(DISTINCT a.store_id) AS total_operational_stores,
		COUNT(DISTINCT d.store_country) AS total_operational_country,
		COUNT(DISTINCT e.region_id) AS total_operational_region,
		COUNT(DISTINCT transaction_date) AS total_active_days,
		COUNT(DISTINCT d.store_city) AS total_unique_cities
	FROM store_performance a
	LEFT JOIN store_products b
	ON b.product_id = a.product_id
	LEFT JOIN customer c
	ON a.customer_id = c.customer_id
	LEFT JOIN store d
	ON d.store_id = a.store_id
	LEFT JOIN regions e
	ON e.region_id = d.region_id
),
transactions AS (
	SELECT 
	COUNT(*) AS total_transactions
	FROM (
		SELECT 
			transaction_date, 
			customer_id, 
			COUNT(transaction_id) AS number
		FROM store_performance a
		GROUP BY transaction_date, customer_id
		ORDER BY transaction_date
	)
)

SELECT
	-- financial
	total_revenue,
	total_cost,
	total_profit,
	-- volume
	total_transactions,
	total_quantity_sold,
	-- product/brand
	total_unique_products_sold,
	total_unique_brands_sold,
	-- customer
	total_buying_customers,
	-- time
	total_active_days,
	-- geographical
	total_operational_stores,
	total_operational_country,
	total_operational_region
FROM sold_kpi
CROSS JOIN transactions







;