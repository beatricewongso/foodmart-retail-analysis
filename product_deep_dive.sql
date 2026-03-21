-- checking the general feel of the product table
	-- how many products do we have? -> 1560
	SELECT COUNT(*), COUNT(DISTINCT product_brand)
	FROM store_products;
	-- turns out, we have 1 product that has not been bought yet (1559)
	SELECT product_id
	FROM store_products
	WHERE product_id NOT IN
		(SELECT product_id
		FROM store_performance)
	-- product_id 1560 has not been bought yet, let's take a closer look -> CDR grape jelly
	SELECT *
	FROM store_products
	WHERE product_id = 1560
	-- how about other products under this brand -> maybe it's a new product, their strawberry & apple jelly has sold ~170 units
	SELECT 
		a.product_id,
		product_name,
		SUM(quantity)
	FROM store_performance a
	LEFT JOIN store_products b
	ON b.product_id = a.product_id
	WHERE product_brand = 'CDR'
	GROUP BY 1,2
	-- are there any products with cost > price -> no
	SELECT 
		product_brand,
		product_name,
		product_retail_price,
		product_cost
	FROM store_products
	WHERE product_cost < product_retail_price 

-- let's take a deeper dive 
CREATE VIEW cte_1 AS (
SELECT
	product_id,
	unit,
	ROUND(SUM(unit) OVER (), 2) AS total_unit,
	ROUND(unit/SUM(unit) OVER () * 100,4) AS pct_unit,
	revenue,
	ROUND(SUM(revenue) OVER (), 2) AS total_revenue,
	ROUND(revenue/SUM(revenue) OVER ()*100,4) AS pct_revenue,
	cost,
	ROUND(SUM(cost) OVER (), 2) AS total_cost,
	ROUND(cost/SUM(cost) OVER () * 100, 4) AS pct_cost,
	revenue - cost AS profit,
	ROUND((revenue - cost)/revenue * 100, 4) AS profit_margin
FROM (
SELECT
	a.product_id,
	SUM(quantity)::NUMERIC AS unit,
	SUM(product_retail_price * quantity)::NUMERIC AS revenue,
	SUM(quantity * product_cost)::NUMERIC AS cost
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
GROUP BY 1
	)
)
CREATE VIEW avg AS (
SELECT
	ROUND(AVG(unit),2) AS avg_unit,
	ROUND(AVG(cte_1.profit_margin),2) AS avg_margin,
	ROUND(AVG(revenue),2) AS avg_revenue,
	ROUND(AVG(cost),2) AS avg_cost
FROM cte_1
)
CREATE VIEW stat AS (
SELECT
	MAX(unit) AS max_unit,
	MIN(unit) AS min_unit,
	ROUND(MAX(revenue),2) AS max_revenue,
	MIN(revenue) AS min_revenue,
	MAX(cost) AS max_cost,
	MIN(cost) AS min_cost,
	MAX(profit_margin) AS max_margin,
	MIN(profit_margin) AS min_margin
FROM cte_1
)
-- let's take it from the simplest measure: quantity sold
--  top 5 best-seller product in terms of quantity -> 2nd and 3rd have lower margins than the average
SELECT
	product_name,
	product_brand,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100,2) AS unit_to_avg_perc,
	ROUND(revenue,2) AS revenue,
	avg_revenue,
	max_revenue,
	ROUND(revenue/avg_revenue * 100, 2) AS rev_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_diff
FROM 
(SELECT
	product_id,
	unit,
	revenue,
	profit_margin
FROM cte_1
ORDER BY 2 DESC
LIMIT 5) a
JOIN store_products b
ON a.product_id = b.product_id
CROSS JOIN avg
CROSS JOIN stat
ORDER BY 3 DESC


-- bottom 5 products in terms of quantity
SELECT
	product_name,
	product_brand,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100,2) AS unit_to_avg_perc,
	ROUND(revenue,2) AS revenue,
	avg_revenue,
	max_revenue,
	ROUND(revenue/avg_revenue * 100, 2) AS rev_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_diff
FROM 
(SELECT
	product_id,
	unit,
	revenue,
	profit_margin
FROM cte_1
ORDER BY 2 
LIMIT 5) a
JOIN store_products b
ON a.product_id = b.product_id 
CROSS JOIN avg
CROSS JOIN stat
ORDER BY 3

-- top 5 products in terms of revenue (price & quantity wise) -> 4 of 5 of these products have lower margins than the average
SELECT
	product_name,
	product_brand,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100,2) AS unit_to_avg_perc,
	ROUND(revenue,2) AS revenue,
	avg_revenue,
	max_revenue,
	ROUND(revenue/avg_revenue * 100, 2) AS rev_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_diff
FROM (SELECT
	product_id,
	revenue,
	unit,
	profit_margin
FROM cte_1
ORDER BY 2 DESC
LIMIT 5) a
JOIN store_products b
ON a.product_id = b.product_id
CROSS JOIN avg
CROSS JOIN stat
ORDER BY revenue DESC


-- bottom 5 products in terms of revenue
SELECT
	product_name,
	product_brand,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100,2) AS unit_to_avg_perc,
	ROUND(revenue,2) AS revenue,
	avg_revenue,
	max_revenue,
	ROUND(revenue/avg_revenue * 100, 2) AS rev_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_diff
FROM (SELECT
	product_id,
	revenue,
	unit,
	profit_margin
FROM cte_1
ORDER BY 2 
LIMIT 5) a
JOIN store_products b
ON a.product_id = b.product_id
CROSS JOIN avg
CROSS JOIN stat
ORDER BY revenue
	


-- top 5 products in terms of profit margin
SELECT
	product_name,
	product_brand,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100,2) AS unit_to_avg_perc,
	ROUND(revenue,2) AS revenue,
	avg_revenue,
	max_revenue,
	ROUND(revenue/avg_revenue * 100, 2) AS rev_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_diff
FROM (SELECT
	product_id,
	revenue,
	unit,
	profit_margin
FROM cte_1
ORDER BY 4 DESC
LIMIT 5) a
JOIN store_products b
ON a.product_id = b.product_id
CROSS JOIN avg
CROSS JOIN stat
ORDER BY profit_margin DESC


-- top 5 products with the worst profit margin -> most are bought above avg, but have revenue way under avg
SELECT
	product_name,
	product_brand,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100,2) AS unit_to_avg_perc,
	ROUND(revenue,2) AS revenue,
	avg_revenue,
	max_revenue,
	ROUND(revenue/avg_revenue * 100, 2) AS rev_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_diff
FROM (SELECT
	product_id,
	revenue,
	unit,
	profit_margin
FROM cte_1
ORDER BY 4 
LIMIT 5) a
JOIN store_products b
ON a.product_id = b.product_id
CROSS JOIN avg
CROSS JOIN stat
ORDER BY profit_margin


-- top 5 products in terms of transaction quantity
SELECT
	product_name,
	product_brand,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100,2) AS unit_to_avg_perc,
	ROUND(revenue,2) AS revenue,
	avg_revenue,
	max_revenue,
	ROUND(revenue/avg_revenue * 100, 2) AS rev_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_diff,
	txn_count
FROM (
SELECT
	a.product_id,
	product_name,
	product_brand,
	COUNT(DISTINCT txn_date) AS txn_count
FROM (
SELECT	
	DISTINCT transaction_date AS txn_date,
	customer_id,
	a.product_id
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
ORDER BY 1,2
) a
JOIN store_products c ON a.product_id = c.product_id
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 5
) a
JOIN cte_1 b ON a.product_id = b.product_id
CROSS JOIN avg
CROSS JOIN stat
ORDER BY txn_count DESC


-- bottom 5 products in terms of transaction quantity
SELECT
	product_name,
	product_brand,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100,2) AS unit_to_avg_perc,
	ROUND(revenue,2) AS revenue,
	avg_revenue,
	max_revenue,
	ROUND(revenue/avg_revenue * 100, 2) AS rev_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_diff,
	txn_count
FROM (
SELECT
	a.product_id,
	product_name,
	product_brand,
	COUNT(DISTINCT txn_date) AS txn_count
FROM (
SELECT	
	DISTINCT transaction_date AS txn_date,
	customer_id,
	a.product_id
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
ORDER BY 1,2
) a
JOIN store_products c ON a.product_id = c.product_id
GROUP BY 1,2,3
ORDER BY 4 
LIMIT 5
) a
JOIN cte_1 b ON a.product_id = b.product_id
CROSS JOIN avg
CROSS JOIN stat
ORDER BY txn_count 



-- top 5 products in terms of basket size
SELECT
	product_name,
	product_brand,
	unit,
	avg_unit,
	max_unit,
	unit_to_avg_perc,
	revenue,
	avg_revenue,
	max_revenue,
	rev_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	margin_diff,
	txn_count,
	unit/txn_count AS basket_size
FROM (
SELECT
	product_name,
	product_brand,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100,2) AS unit_to_avg_perc,
	ROUND(revenue,2) AS revenue,
	avg_revenue,
	max_revenue,
	ROUND(revenue/avg_revenue * 100, 2) AS rev_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_diff,
	txn_count
FROM (
SELECT
	a.product_id,
	product_name,
	product_brand,
	COUNT(DISTINCT txn_date) AS txn_count
FROM (
SELECT	
	DISTINCT transaction_date AS txn_date,
	customer_id,
	a.product_id
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
ORDER BY 1,2
) a
JOIN store_products c ON a.product_id = c.product_id
GROUP BY 1,2,3
) a
JOIN cte_1 b ON a.product_id = b.product_id
CROSS JOIN avg
CROSS JOIN stat
)
ORDER BY basket_size DESC
LIMIT 5

-- bottom 5 products in terms of basket size
SELECT
	product_name,
	product_brand,
	unit,
	avg_unit,
	max_unit,
	unit_to_avg_perc,
	revenue,
	avg_revenue,
	max_revenue,
	rev_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	margin_diff,
	txn_count,
	unit/txn_count AS basket_size
FROM (
SELECT
	product_name,
	product_brand,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100,2) AS unit_to_avg_perc,
	ROUND(revenue,2) AS revenue,
	avg_revenue,
	max_revenue,
	ROUND(revenue/avg_revenue * 100, 2) AS rev_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_diff,
	txn_count
FROM (
SELECT
	a.product_id,
	product_name,
	product_brand,
	COUNT(DISTINCT txn_date) AS txn_count
FROM (
SELECT	
	DISTINCT transaction_date AS txn_date,
	customer_id,
	a.product_id
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
ORDER BY 1,2
) a
JOIN store_products c ON a.product_id = c.product_id
GROUP BY 1,2,3
) a
JOIN cte_1 b ON a.product_id = b.product_id
CROSS JOIN avg
CROSS JOIN stat
)
ORDER BY basket_size 
LIMIT 5

-- top 10 highest price products -> Carlson occupies 3 spots out of 10
SELECT
	product_name,
	product_brand,
	unit,
	product_retail_price,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100,2) AS unit_to_avg_perc,
	ROUND(revenue,2),
	avg_revenue,
	max_revenue,
	ROUND(revenue/avg_revenue * 100, 2) AS rev_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_diff
FROM store_products a
JOIN cte_1 b 
ON a.product_id = b.product_id
CROSS JOIN avg
CROSS JOIN stat
ORDER BY product_retail_price DESC
LIMIT 10

-- top 10 lowest price products => most sold 60-115% avg, one in particular had -10 diff from avg profit margin
SELECT
	product_name,
	product_brand,
	product_retail_price,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100,2) AS unit_to_avg_perc,
	ROUND(revenue,2),
	avg_revenue,
	max_revenue,
	ROUND(revenue/avg_revenue * 100, 2) AS rev_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_diff
FROM store_products a
JOIN cte_1 b 
ON a.product_id = b.product_id
CROSS JOIN avg
CROSS JOIN stat
ORDER BY product_retail_price
LIMIT 10

-- top 10 highest cost products => all have negative margin
SELECT
	product_name,
	product_brand,
	product_cost,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100,2) AS unit_to_avg_perc,
	ROUND(revenue,2),
	avg_revenue,
	max_revenue,
	ROUND(revenue/avg_revenue * 100, 2) AS rev_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_diff
FROM store_products a
JOIN cte_1 b 
ON a.product_id = b.product_id
CROSS JOIN avg
CROSS JOIN stat
ORDER BY product_cost DESC
LIMIT 10

-- top 10 lowest cost products
SELECT
	product_name,
	product_brand,
	product_cost,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100,2) AS unit_to_avg_perc,
	ROUND(revenue,2),
	avg_revenue,
	max_revenue,
	ROUND(revenue/avg_revenue * 100, 2) AS rev_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_diff
FROM store_products a
JOIN cte_1 b 
ON a.product_id = b.product_id
CROSS JOIN avg
CROSS JOIN stat
ORDER BY product_cost
LIMIT 10

-- how are low_fat and recyclable products doing
	-- low_fat products: 552, the other 1 has not been bought yet, hence the list only contains 551 products
CREATE VIEW low_fat AS (
	SELECT
		product_name,
		product_brand,
		unit,
		revenue,
		cost,
		profit_margin
	FROM cte_1 a
	JOIN store_products b
	ON a.product_id = b.product_id
	WHERE a.product_id IN (
	SELECT
	product_id
	FROM store_products 
	WHERE low_fat = TRUE
	)
)

-- top 5 most bought low fat products => dairy low_fat products still have positive margins
SELECT
	product_name,
	product_brand,
	revenue,
	unit,
	avg_unit,
	ROUND(unit/avg_unit * 100, 2) AS unit_to_avg_perc,
	profit_margin,
	avg_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_diff
FROM low_fat
CROSS JOIN avg
ORDER BY 4 DESC
LIMIT 5


-- top 5 most profitable low fat products => really good margins considering max profit margin is 70, though lacking in units bought (4/5 are lower than average)
SELECT
	product_name,
	product_brand,
	revenue,
	unit,
	avg_unit,
	ROUND(unit/avg_unit * 100, 2) AS unit_to_avg_perc,
	profit_margin,
	avg_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_diff
FROM low_fat
CROSS JOIN avg
ORDER BY 7 DESC
LIMIT 5

-- now let's go to recyclable products
	-- there are 873 recyclable products
CREATE VIEW recyclable AS (
SELECT
	product_name,
	product_brand,
	unit,
	revenue,
	cost,
	profit_margin
FROM cte_1 a
JOIN store_products b
ON  a.product_id = b.product_id
WHERE a.product_id IN (
SELECT
	product_id
FROM store_products
WHERE recyclable = TRUE)
)

-- top 5 most sold recyclable products => one of them have a profit margin lower than average and one is only slightly higher than average
SELECT
	product_name,
	product_brand,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100, 2) AS unit_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_to_avg_perc
FROM recyclable
CROSS JOIN avg
CROSS JOIN stat
ORDER BY unit DESC
LIMIT 5


-- top 5 most profitable recyclable products
SELECT
	product_name,
	product_brand,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100, 2) AS unit_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_to_avg_perc
FROM recyclable
CROSS JOIN avg
CROSS JOIN stat
ORDER BY profit_margin DESC
LIMIT 5

-- both recyclable and low_fat products => 299 products
CREATE VIEW double AS (
SELECT 
	product_name,
	product_brand,
	unit,
	revenue,
	cost,
	profit_margin
FROM cte_1 a
JOIN store_products b
ON a.product_id = b.product_id
WHERE a.product_id IN (
SELECT product_id
FROM store_products
WHERE recyclable = TRUE AND low_fat = TRUE
)
)

-- top 5 most bought recyclable & low fat products => 3 has lower margin than average
SELECT 
	product_name,
	product_brand,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100, 2) AS unit_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_to_avg_perc
FROM double
CROSS JOIN avg
CROSS JOIN stat
ORDER BY unit DESC
LIMIT 5

-- top 5 most profitable recyclable & low fat products 
SELECT 
	product_name,
	product_brand,
	unit,
	avg_unit,
	max_unit,
	ROUND(unit/avg_unit * 100, 2) AS unit_to_avg_perc,
	profit_margin,
	avg_margin,
	max_margin,
	ROUND(profit_margin - avg_margin, 2) AS margin_to_avg_perc
FROM double
CROSS JOIN avg
CROSS JOIN stat
ORDER BY profit_margin DESC
LIMIT 5