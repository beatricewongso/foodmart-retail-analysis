-- transaction, revenue, profit and profit margin per store type
SELECT
	kpi.store_type,
	qty,
	txn_count,
	ROUND(qty/txn_count) AS avg_basket,
	ROUND(revenue/txn_count,2) AS avg_txn_value,
	ROUND(revenue, 2) AS revenue,
	ROUND(cost, 2) AS cost,
	ROUND(profit, 2) AS profit,
	ROUND(profit/revenue * 100, 2) AS profit_margin
FROM (
SELECT
	c.store_type,
	SUM(quantity) AS qty,
	SUM(quantity * product_retail_price)::NUMERIC AS revenue,
	SUM(quantity * product_cost)::NUMERIC AS cost,
	(SUM(quantity * product_retail_price) - SUM(quantity * product_cost))::NUMERIC AS profit
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
LEFT JOIN store c
ON a.store_id = c.store_id
GROUP BY 1
) kpi
JOIN 
(SELECT
	store_type,
	COUNT(txn_date)::NUMERIC AS txn_count
FROM (
SELECT
	DISTINCT transaction_date::DATE AS txn_date,
	customer_id,
	store_type
FROM store_performance a
LEFT JOIN store b
ON a.store_id = b.store_id
)
GROUP BY 1) txn
ON kpi.store_type = txn.store_type

-- transaction per member card in every kinds of store
SELECT
	store_type,
	member_card,
	txn_count,
	RANK() OVER (PARTITION BY store_type ORDER BY txn_count DESC) AS rank
FROM (
SELECT
	store_type,
	member_card,
	COUNT(customer_id) AS txn_count
FROM (
SELECT
	DISTINCT transaction_date,
	a.customer_id,
	store_type,
	member_card
FROM store_performance a
LEFT JOIN store b ON a.store_id = b.store_id
LEFT JOIN customer c ON a.customer_id = c.customer_id
ORDER BY 2
)
GROUP BY 1,2 
ORDER BY 1,2
)

----- time related: weekday vs weekend 
-- transaction
WITH txn AS (
SELECT
	month,
	CASE
	WHEN dow IN (6,0) THEN 'Weekend'
	ELSE 'Weekday'
	END AS week_indicator,
	COUNT(*) AS txn_count
FROM (
SELECT
	EXTRACT(month from txn_date) AS month,
	EXTRACT(dow from txn_date) AS dow,
	customer_id
FROM (
SELECT
	DISTINCT transaction_date::DATE AS txn_date,
	customer_id
FROM store_performance a
ORDER BY 1
)
) 
GROUP BY 1,2
ORDER BY 1,2
),
rev AS (
SELECT
	month,
	CASE
	WHEN dow IN (6,0) THEN 'Weekend'
	ELSE 'Weekday'
	END AS week_indicator,
	SUM(revenue) As revenue
FROM (
SELECT
	EXTRACT(month from txn_date) AS month,
	EXTRACT(dow from txn_date) AS dow,
	customer_id,
	revenue
FROM (
SELECT
	DISTINCT transaction_date::DATE AS txn_date,
	customer_id,
	ROUND(SUM(quantity * product_retail_price)::NUMERIC,2) AS revenue
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
GROUP BY 1,2
ORDER BY 1,2 
)
)
GROUP BY 1,2
ORDER BY 1,2
)

SELECT
	rev.month,
	rev.week_indicator,
	txn_count,
	revenue
FROM rev
JOIN txn ON rev.month = txn.month 
AND rev.week_indicator = txn.week_indicator



--- time related: profit margin over month
SELECT
	txn_month,
	store_type,
	profit_margin,
	RANK() OVER (PARTITION BY txn_month ORDER BY profit_margin DESC),
	ROUND(AVG(profit_margin) OVER (PARTITION BY txn_month ORDER BY txn_month),3) AS monthly_profit_margin
FROM (
SELECT
	txn_month,
	store_type,
	ROUND(AVG(profit_margin),2) AS profit_margin
FROM (
SELECT
	EXTRACT(MONTH FROM txn_date) AS txn_month,
	store_type,
	spending,
	ROUND(profit/spending*100, 2) AS profit_margin
FROM (
SELECT
	DISTINCT(transaction_date) AS txn_date,
	a.customer_id,
	c.store_type,
	ROUND(SUM(quantity * product_retail_price)::NUMERIC,2) AS spending,
	ROUND((SUM(quantity * product_retail_price)-SUM(quantity * product_cost))
	::NUMERIC, 2) AS profit
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
LEFT JOIN store c
ON a.store_id = c.store_id
GROUP BY 1, 2, 3
ORDER BY 2
)
ORDER BY 1,2
)
GROUP BY 1,2
)

-- time related: avg txn value over month
WITH store_monthly_rev AS (
SELECT
	txn_month,
	store_type,
	revenue,
	RANK() OVER (PARTITION BY txn_month ORDER BY revenue),
	SUM(revenue) OVER (PARTITION BY txn_month ORDER BY txn_month) AS monthly_spend
FROM (
SELECT
	txn_month,
	store_type,
	SUM(revenue) AS revenue
FROM (
SELECT
	EXTRACT(MONTH FROM txn_date) AS txn_month,
	store_type,
	revenue
FROM (
SELECT
	DISTINCT(transaction_date) AS txn_date,
	a.customer_id,
	c.store_type,
	ROUND(SUM(quantity * product_retail_price)::NUMERIC, 2) AS revenue
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
LEFT JOIN store c
ON a.store_id = c.store_id
GROUP BY 1, 2, 3
ORDER BY 2
)
ORDER BY 1,2
)
GROUP BY 1,2
)
),
store_monthly_txn AS (
SELECT
	txn_month,
	store_type,
	txn,
	RANK() OVER (PARTITION BY txn_month ORDER BY txn DESC)
FROM (
SELECT
	EXTRACT(MONTH FROM txn_date) AS txn_month,
	store_type,
	COUNT(*)::NUMERIC AS txn
FROM (
SELECT
	DISTINCT(transaction_date) AS txn_date,
	a.customer_id,
	c.store_type
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
LEFT JOIN store c
ON a.store_id = c.store_id
GROUP BY 1, 2, 3
ORDER BY 2
)
GROUP BY 1, 2
ORDER BY 1, 2
)
)

SELECT
	txn_month,
	store_type,
	revenue,
	txn,
	avg_txn_value,
	RANK() OVER (PARTITION BY txn_month ORDER BY avg_txn_value) AS rank
FROM (
SELECT
	a.txn_month,
	a.store_type,
	revenue,
	txn,
	ROUND(revenue/txn) AS avg_txn_value
FROM store_monthly_rev a
JOIN store_monthly_txn b
ON a.txn_month = b.txn_month
AND a.store_type = b.store_type
)



----- temporary tables: 

CREATE VIEW cte_2 AS (
SELECT
	customer_id,
	unit,
	ROUND(SUM(unit) OVER (), 2) AS total_unit,
	ROUND(unit/SUM(unit) OVER () * 100,4) AS pct_unit,
	revenue,
	ROUND(SUM(revenue) OVER (), 2) AS total_revenue,
	ROUND(revenue/SUM(revenue) OVER ()*100,4) AS pct_revenue,
	product_cost,
	ROUND(SUM(product_cost) OVER (), 2) AS total_product_cost,
	ROUND(product_cost/SUM(product_cost) OVER () * 100, 4) AS pct_product_cost,
	revenue - product_cost AS profit,
	ROUND((revenue - product_cost)/revenue * 100, 4) AS profit_margin
FROM (
SELECT
	a.customer_id,
	SUM(quantity)::NUMERIC AS unit,
	SUM(product_retail_price * quantity)::NUMERIC AS revenue,
	SUM(quantity * product_cost)::NUMERIC AS product_cost
FROM store_performance a
LEFT JOIN customer b
ON a.customer_id = b.customer_id
LEFT JOIN store_products c
ON a.product_id = c.product_id
GROUP BY 1
	)
)
CREATE VIEW avg AS (
SELECT
	ROUND(AVG(unit),2) AS avg_unit,
	ROUND(AVG(profit_margin),2) AS avg_margin,
	ROUND(AVG(revenue),2) AS avg_revenue,
	ROUND(AVG(product_cost),2) AS avg_product_cost
FROM cte_2
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

CREATE VIEW transaction_2 AS (
WITH agg_txn AS (
SELECT
	ROUND(AVG(txn),2) AS avg_txn, -- 3.68
	MAX(txn) AS max_txn, -- 27
	MIN(txn) AS min_txn -- 1
FROM (
SELECT
	customer_id,
	COUNT(DISTINCT transaction_date)::NUMERIC AS txn
FROM store_performance a
GROUP BY 1
)
)

SELECT
	customer_id,
	txn,
	avg_txn,
	SUM(txn) OVER (),
	max_txn,
	min_txn
FROM (
SELECT
	customer_id,
	COUNT(DISTINCT transaction_date) AS txn
FROM store_performance a
GROUP BY 1
)
CROSS JOIN agg_txn
)
