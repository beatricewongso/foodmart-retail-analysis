WITH transaction AS (
SELECT
	member_card,
	SUM(txn) AS total_member_txn,
	SUM(SUM(txn)) OVER () AS total_txn,
	ROUND(SUM(txn) / SUM(SUM(txn)) OVER () * 100, 2) AS txn_perc_per_member
FROM (
	SELECT
		b.member_card,
		COUNT(a.customer_id)::NUMERIC AS txn
	FROM (
		SELECT
			transaction_date,
			customer_id,
			COUNT(customer_id)
		FROM store_performance
		GROUP BY 1, 2
		ORDER BY 1, 2
	) AS a
	LEFT JOIN customer b
		ON a.customer_id = b.customer_id
	GROUP BY 1
) AS subquery
GROUP BY member_card
),
rev AS (
	SELECT
		member_card,
		rev AS total_member_rev,
		SUM(rev) OVER () AS total_rev,
		ROUND(rev/SUM(rev) OVER () *100,2) AS rev_perc_per_member
	FROM (
	SELECT
		b.member_card,
		ROUND(SUM(quantity * product_retail_price)::NUMERIC,2) AS rev
	FROM store_performance a
	LEFT JOIN customer b
	ON a.customer_id = b.customer_id
	LEFT JOIN store_products c
	ON a.product_id = c.product_id
	GROUP BY 1
	)
),
cust AS (
	SELECT 
		member_card,
		cust AS total_member_cust,
		SUM(cust) OVER () AS total_cust,
		ROUND(cust/SUM(cust) OVER () * 100,2) AS cust_perc_per_member
	FROM (
	SELECT
		member_card,
		COUNT(DISTINCT a.customer_id)::NUMERIC AS cust
	FROM customer a
	GROUP BY 1
	)
),
act_cust AS (
	SELECT
		member_card,
		act_cust total_member_act_cust,
		SUM(act_cust) OVER () AS total_act_cust,
		ROUND(act_cust/SUM(act_cust) OVER () * 100, 2) AS act_cust_perc_per_member
	FROM (
	SELECT 
		member_card,
		COUNT(*)::NUMERIC AS act_cust
	FROM (
	SELECT
		customer_id,
		COUNT(DISTINCT transaction_date)
	FROM store_performance
	GROUP BY 1
	) a
	LEFT JOIN customer b
	ON a.customer_id = b.customer_id
	GROUP BY 1
	)
),
qty AS (
	SELECT
		member_card,
		qty AS total_member_qty,
		SUM(qty) OVER () total_qty,
		ROUND(qty/SUM(qty) OVER ()*100,2) AS qty_perc_per_member
	FROM (
	SELECT
		member_card,
		SUM(quantity)::NUMERIC AS qty
	FROM store_performance a
	LEFT JOIN customer b
	ON a.customer_id = b.customer_id
	GROUP BY 1
	)
),
profit AS (
	SELECT
		member_card,
		profit AS total_member_profit,
		SUM(profit) OVER () total_profit,
		ROUND(profit/SUM(profit) OVER () *100,2) AS profit_perc_per_member
	FROM (
	SELECT
		b.member_card,
		ROUND((SUM(quantity * product_retail_price) - SUM(quantity * product_cost))::NUMERIC,2) AS profit
	FROM store_performance a
	LEFT JOIN customer b
	ON a.customer_id = b.customer_id
	LEFT JOIN store_products c
	ON a.product_id = c.product_id
	GROUP BY 1
	)
)

SELECT
	a.member_card,
	total_member_txn,
	txn_perc_per_member,
	total_member_rev,
	rev_perc_per_member,
	total_member_cust,
	cust_perc_per_member,
	total_member_qty,
	qty_perc_per_member,
	total_member_profit,
	profit_perc_per_member
FROM transaction a
	JOIN rev b ON a.member_card = b.member_card
	JOIN cust c ON a.member_card = c.member_card
	JOIN act_cust d ON a.member_card = d.member_card
	JOIN qty e ON a.member_card = e.member_card
	JOIN profit f ON a.member_card = f.member_card
