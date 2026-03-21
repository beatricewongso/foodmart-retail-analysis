WITH fact AS (
	SELECT 
		COUNT(store_id)::NUMERIC AS store,
		COUNT(DISTINCT store_country)::NUMERIC AS country
	FROM (
		SELECT
			store_id,
			store_country,
			store_state
		FROM store
		)
),
operational AS (
	SELECT
		COUNT(DISTINCT store_id)::NUMERIC AS op_store,
		COUNT(DISTINCT store_country)::NUMERIC As op_country,
		COUNT(DISTINCT store_state)::NUMERIC AS op_state -- Oregon, Washington, California
	FROM (
		SELECT
			DISTINCT(a.store_id),
			store_country,
			store_state
		FROM store_performance a
		LEFT JOIN store b
		ON a.store_id = b.store_id
		)
),
USA_state_op_check AS (
	SELECT
		store_state,
		COUNT(store_id)
	FROM store
	WHERE store_country='USA'
	GROUP BY 1
	EXCEPT
	SELECT
		store_state,
		COUNT(DISTINCT a.store_id)
	FROM store_performance a
	LEFT JOIN store b
	ON a.store_id = b.store_id
	GROUP BY 1
)


-- store's only active in USA
SELECT 
	ROUND(op_store/store,2) AS operational_store_to_total,
	ROUND(op_country/country,2) AS operational_country_to_total
FROM fact
CROSS JOIN operational;


-- digging into stores that aren't operational:
-- are there any stores in USA but not operational => no, the only ones that are non-operational are Mexico and Canada
SELECT
	store_id,
	store_country
FROM store
WHERE store_id NOT IN (
	SELECT DISTINCT store_id
	FROM store_performance
);


	
	
	