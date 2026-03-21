WITH 
transactions AS (
	SELECT COUNT(*):: NUMERIC AS txn_total
	FROM (
		SELECT
			transaction_date,
			customer_id,
			COUNT(customer_id)
		FROM store_performance a
		GROUP BY 1,2
		ORDER BY 1,2
	)
),
active AS (
	SELECT 
		COUNT(DISTINCT transaction_date)::NUMERIC AS act_days,
		COUNT(DISTINCT customer_id)::NUMERIC AS act_cust,
		SUM(quantity * product_retail_price)::NUMERIC AS rev,
		(SUM(quantity * product_retail_price) - SUM(quantity * product_cost))::NUMERIC AS profit
	FROM store_performance a
	LEFT JOIN store_products b
	ON a.product_id = b.product_id
),
rev_mo_best AS (
	SELECT
		month AS best_month_revenue
	FROM(
		SELECT
			EXTRACT(MONTH FROM DATE_TRUNC('month',transaction_date)) AS month,
			ROUND(SUM(quantity * product_retail_price)::NUMERIC,2) AS rev_month
		FROM store_performance a
		LEFT JOIN store_products b
		ON a.product_id = b.product_id
		GROUP BY 1
		ORDER BY 2 DESC
		)
	LIMIT 1
),
rev_mo_worst AS (
	SELECT
		month AS worst_month_revenue
	FROM(
		SELECT
			EXTRACT(MONTH FROM DATE_TRUNC('month',transaction_date)) AS month,
			ROUND(SUM(quantity * product_retail_price)::NUMERIC,2) AS rev_month
		FROM store_performance a
		LEFT JOIN store_products b
		ON a.product_id = b.product_id
		GROUP BY 1
		ORDER BY 2 ASC
		)
	LIMIT 1
),
pro_mo_best AS (
	SELECT
		month AS best_month_profit
	FROM (
		SELECT
		    EXTRACT(MONTH FROM DATE_TRUNC('month', transaction_date)) AS month,
		    ROUND((SUM(quantity * product_retail_price) - SUM(quantity * product_cost))::NUMERIC,2) AS prof_month
		FROM store_performance a
		LEFT JOIN store_products b
		    ON a.product_id = b.product_id
		GROUP BY 1
		ORDER BY 2 DESC
		)
	LIMIT 1
		
),
pro_mo_worst AS (
	SELECT
		month AS worst_month_profit
	FROM (
		SELECT
		    EXTRACT(MONTH FROM DATE_TRUNC('month', transaction_date)) AS month,
		    ROUND((SUM(quantity * product_retail_price) - SUM(quantity * product_cost))::NUMERIC,2) AS prof_month
		FROM store_performance a
		LEFT JOIN store_products b
		    ON a.product_id = b.product_id
		GROUP BY 1
		ORDER BY 2 
		)
	LIMIT 1		
)

SELECT
	ROUND(txn_total/act_days,0) AS avg_daily_txn_act,
	ROUND(txn_total/365,0) AS avg_daily_txn_cal,
	ROUND(txn_total/12,0) AS avg_monthly_txn,
	ROUND(act_cust/12,0) AS avg_monthly_act_cust,
	ROUND(rev/12,2) AS avg_monthly_rev,
	ROUND(profit/12,2) AS avg_monthly_profit,
	best_month_revenue,
	worst_month_revenue,
	best_month_profit,
	worst_month_profit
FROM transactions
CROSS JOIN active
CROSS JOIn rev_mo_best
CROSS JOIN pro_mo_best
CROSS JOIN rev_mo_worst
CROSS JOIN pro_mo_worst


-- busiest DOW
SELECT
	dow AS busiest
FROM (
	SELECT
		DISTINCT(EXTRACT(DOW FROM transaction_date)) AS dow,
		COUNT(transaction_date) AS txn
	FROM (
		SELECT
		transaction_date,
		customer_id,
		COUNT(customer_id)
		FROM store_performance a
		GROUP BY 1,2
		ORDER BY 1,2
		)
GROUP BY 1
ORDER BY 2 DESC
)
LIMIT 3

-- weekend vs weekday revenue
SELECT 
	CASE
	WHEN EXTRACT(DOW FROM transaction_date) IN (0, 6) THEN 'Weekend'
    ELSE 'Weekday'
	END AS day_type,
	ROUND(SUM(quantity * product_retail_price)::NUMERIC,2) AS revenue
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
GROUP BY 1

-- weekend vs weekday transaction
SELECT
	CASE
	WHEN EXTRACT(DOW FROM transaction_date) IN (0, 6) THEN 'Weekend'
    ELSE 'Weekday' 
	END AS day_type,
	COUNT(transaction_date)
FROM (
	SELECT
		transaction_date,
		customer_id,
		COUNT(customer_id)
	FROM store_performance a
	GROUP BY 1,2
	ORDER BY 1,2
)
GROUP BY 1
