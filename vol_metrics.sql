WITH transaction AS (
	SELECT
		CAST(COUNT(*) AS numeric) AS total_transaction
	FROM (
		SELECT
			transaction_date,
			customer_id,
			COUNT(customer_id)
		FROM store_performance
		GROUP BY 1,2
		ORDER BY 1,2
	)
),
buying AS (
	SELECT
		CAST(COUNT(DISTINCT customer_id) AS numeric) AS buying_customer,
		CAST(SUM(quantity) AS numeric) AS units_sold,
		CAST(COUNT(DISTINCT store_id) AS numeric) AS active_store
	FROM store_performance
)

SELECT
	ROUND(units_sold/buying_customer,2) AS avg_unit_per_customer,
	ROUND(units_sold/total_transaction,2) AS avg_basket_size,
	ROUND(total_transaction/buying_customer,2) AS txn_count_per_customer,
	ROUND(total_transaction/active_store,2) AS txn_count_per_store
FROM transaction
CROSS JOIN buying



