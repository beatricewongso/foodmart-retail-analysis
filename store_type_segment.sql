WITH transaction AS (
SELECT
	store_type,
	SUM(txn) AS total_store_txn,
	SUM(SUM(txn)) OVER () AS total_txn,
	ROUND(SUM(txn) / SUM(SUM(txn)) OVER () * 100, 2) AS txn_perc_per_store
FROM (
	SELECT
		b.store_id,
		b.store_type,
		COUNT(a.store_id)::NUMERIC AS txn
	FROM (
		SELECT
			transaction_date,
			customer_id,
			store_id,
			COUNT(customer_id)
		FROM store_performance
		GROUP BY 1, 2, 3
		ORDER BY 1, 2, 3
	) AS a
	LEFT JOIN store b
		ON a.store_id = b.store_id
	GROUP BY 1, 2
) AS subquery
GROUP BY store_type
),
rev AS (
	SELECT
		store_type,
		rev AS total_store_rev,
		SUM(rev) OVER () AS total_rev,
		ROUND(rev/SUM(rev) OVER () *100,2) AS rev_perc_per_store
	FROM (SELECT
		b.store_type,
		ROUND(SUM(quantity * product_retail_price)::NUMERIC,2) AS rev
	FROM store_performance a
	LEFT JOIN store b
	ON a.store_id = b.store_id
	LEFT JOIN store_products c
	ON a.product_id = c.product_id
	GROUP BY 1
	)
),
cust AS (
	SELECT 
		store_type,
		cust AS total_store_cust,
		SUM(cust) OVER () AS total_cust,
		ROUND(cust/SUM(cust) OVER () * 100,2) AS cust_perc_per_store
	FROM (
	SELECT
		store_type,
		COUNT(DISTINCT a.customer_id)::NUMERIC AS cust
	FROM customer a
	JOIN store_performance b
	ON a.customer_id = b.customer_id
	LEFT JOIN store c
	ON b.store_id = c.store_id
	GROUP BY 1
	)
),
qty AS (
	SELECT
		store_type,
		qty AS total_store_qty,
		SUM(qty) OVER () total_qty,
		ROUND(qty/SUM(qty) OVER ()*100,2) AS qty_perc_per_store
	FROM (
	SELECT
		store_type,
		SUM(quantity)::NUMERIC AS qty
	FROM store_performance a
	LEFT JOIN store b
	ON a.store_id = b.store_id
	GROUP BY 1
	)
),
profit AS (
	SELECT
		store_type,
		profit AS total_store_profit,
		SUM(profit) OVER () total_profit,
		ROUND(profit/SUM(profit) OVER () *100,2) AS profit_perc_per_store
	FROM (
	SELECT
		b.store_type,
		ROUND((SUM(quantity * product_retail_price) - SUM(quantity * product_cost))::NUMERIC,2) AS profit
	FROM store_performance a
	LEFT JOIN store b
	ON a.store_id = b.store_id
	LEFT JOIN store_products c
	ON a.product_id = c.product_id
	GROUP BY 1
	)
)

SELECT
	a.store_type,
	total_store_txn,
	txn_perc_per_store,
	total_store_rev,
	rev_perc_per_store,
	total_store_cust,
	cust_perc_per_store,
	total_store_qty,
	qty_perc_per_store,
	total_store_profit,
	profit_perc_per_store
FROM transaction a
	JOIN rev b ON a.store_type = b.store_type
	JOIN cust c ON a.store_type = c.store_type
	JOIN qty d ON a.store_type = d.store_type
	JOIN profit e ON a.store_type = e.store_type
