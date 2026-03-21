-- SELECT table_name, column_name, data_type
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
-- ORDER BY table_name, ordinal_position

WITH fact AS (
	SELECT 
		COUNT(customer_id)::NUMERIC AS total
	FROM customer
),
member AS (
	SELECT
		member_card,
		member_count,
		ROUND((member_count/total_members*100),2) AS member_perc
	FROM (
		SELECT
		    member_card,
		    member_count,
		    SUM(member_count) OVER () AS total_members
		FROM (
		    SELECT
		        member_card,
		        COUNT(customer_id) AS member_count
		    FROM customer
		    GROUP BY member_card
		)
)), 
returning_cust AS (
	SELECT COUNT(*)::NUMERIC AS return
	FROM (
		SELECT 
			customer_id, 
			COUNT(customer_id) AS repeat
		FROM store_performance
		GROUP BY customer_id
		HAVING COUNT(customer_id) > 1
		ORDER BY repeat DESC
	)
),
inactive_cust AS (
	SELECT
		COUNT(*)::NUMERIC AS inactive
	FROM (
		SELECT 
			a.customer_id, 
			COUNT(b.customer_id) AS repeat
		FROM customer a
		LEFT JOIN store_performance b
		ON a.customer_id = b.customer_id
		GROUP BY a.customer_id
		HAVING COUNT(b.customer_id) < 1
		ORDER BY repeat DESC
	)
), 
bought_once AS (
	SELECT
		COUNT(*)::NUMERIC AS once
	FROM (
		SELECT 
			a.customer_id, 
			COUNT(b.customer_id) AS repeat
		FROM customer a
		LEFT JOIN store_performance b
		ON a.customer_id = b.customer_id
		GROUP BY a.customer_id
		HAVING COUNT(b.customer_id) = 1
		ORDER BY repeat DESC
	)
)

SELECT 
	ROUND((return + once)/total,2) AS active_rate,
	ROUND(inactive/total,2) AS inactive_rate,
	ROUND((return/(return+once)),2) AS retention_rate,
	ROUND((once/(return+once)),2) AS churn_rate
FROM fact a
CROSS JOIN returning_cust b
CROSS JOIN inactive_cust c
CROSS JOIN bought_once d





