-- monthly transactions
SELECT
	EXTRACT(MONTH FROM DATE_TRUNC('month', transaction_date)),
	COUNT(*) AS txn
FROM (
	SELECT
		transaction_date,
		customer_id,
		COUNT(customer_id)
	FROM store_performance
	GROUP BY 1,2
	)
GROUP BY 1
ORDER BY 1

-- monthly revenue
SELECT
	EXTRACT(MONTH FROM DATE_TRUNC('month', transaction_date)),
	ROUND(SUM(quantity * product_retail_price)::NUMERIC,2) AS rev
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
GROUP BY 1
ORDER BY 1

-- monthly profit
SELECT
	EXTRACT(MONTH FROM DATE_TRUNC('month', transaction_date)),
	ROUND((SUM(quantity * product_retail_price)-SUM(quantity*product_cost))::NUMERIC,2) AS profit
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
GROUP BY 1
ORDER BY 1


-- monthly active customers
SELECT
    month,
    COUNT(DISTINCT customer_id) AS active_customers
FROM (
    SELECT
        EXTRACT(MONTH FROM DATE_TRUNC('month', transaction_date)) AS month,
        customer_id,
        COUNT(customer_id) AS txn_count
    FROM store_performance
    GROUP BY 1, 2
)
GROUP BY 1
ORDER BY 1

-- monthly new customers
SELECT 
	EXTRACT(MONTH FROM DATE_TRUNC('month', acct_open_date)),
	COUNT(customer_id) AS new_customer
FROM customer
GROUP BY 1
ORDER BY 1

-- cummulative revenue, profit, mom revenue & profit
WITH monthly AS
(
SELECT
	EXTRACT(MONTH FROM DATE_TRUNC('month', transaction_date)) AS month,
	ROUND(SUM(quantity * product_retail_price)::NUMERIC,2) AS rev,
	ROUND((SUM(quantity * product_retail_price)-SUM(quantity*product_cost))::NUMERIC,2) AS profit
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
GROUP BY 1
ORDER BY 1
)

SELECT 
	month,
	SUM(rev) OVER (ORDER BY month) AS rev,
	ROUND((rev-LAG(rev,1) OVER (ORDER BY month))/rev,2) AS mom_rev,
	SUM(profit) OVER (ORDER BY month) profit,
	ROUND((profit - LAG(profit,1) OVER (ORDER BY month))/profit,2) AS mom_profit
FROM monthly


-- quarterly revenue, QoQ revenue & profit
WITH q AS (
	SELECT
		EXTRACT(QUARTER FROM DATE_TRUNC('quarter', transaction_date)) AS quarter,
		ROUND(SUM(quantity * product_retail_price)::NUMERIC,2) AS rev,
		ROUND((SUM(quantity * product_retail_price)-SUM(quantity*product_cost))::NUMERIC,2) AS profit
	FROM store_performance a
	LEFT JOIN store_products b
	ON a.product_id = b.product_id
	GROUP BY 1
	ORDER BY 1
)

SELECT
	quarter,
	rev,
	ROUND((rev - LAG(rev,1) OVER (ORDER BY quarter))/rev,2) AS qoq_rev,
	profit,
	ROUND((profit - LAG(profit,1) OVER (ORDER BY quarter))/profit,2) AS qoq_profit
FROM q