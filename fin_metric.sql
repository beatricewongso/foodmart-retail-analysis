WITH fin_kpi AS (
	SELECT
		CAST(SUM(quantity * product_retail_price) AS numeric) AS total_rev,
		CAST(SUM(quantity * product_cost) AS numeric) AS total_cost,
		CAST(SUM(quantity * product_retail_price) - SUM(quantity * product_cost) AS numeric) AS total_profit
	FROM store_performance a
	LEFT JOIN store_products b
	ON a.product_id = b.product_id
),

transaction AS (
	SELECT
		CAST(COUNT(*) AS numeric) AS total_transactions
	FROM (
		SELECT
			transaction_date,
			customer_id,
			COUNT(customer_id)
		FROM store_performance
		GROUP BY transaction_date, customer_id
		ORDER BY 1,2
	)
),
active AS (
	SELECT 
		CAST(COUNT(DISTINCT customer_id) AS numeric) AS buying_customer,
		CAST(COUNT(DISTINCT a.store_id) AS numeric) AS active_store
	FROM store_performance a 
	LEFT JOIN store b
	ON a.store_id = b.store_id
)

SELECT
	ROUND(total_profit/total_rev*100,2) AS profit_margin_pct,
	ROUND(total_cost/total_rev*100,2) cost_as_pct_revenue,
	ROUND(total_rev/total_transactions,2) AS avg_order_value,
	ROUND(total_profit/total_transactions,2) AS avg_profit_per_transaction,
	ROUND(total_rev/buying_customer,2) AS avg_revenue_per_customer,
	ROUND(total_profit/buying_customer,2) AS avg_profit_per_customer,
	ROUND(total_rev/active_store,2) AS avg_revenue_per_store,
	ROUND(total_profit/active_store,2) AS avg_profit_per_store
FROM fin_kpi
CROSS JOIN transaction
CROSS JOIN active





