-- how many members do we have? => 10281
SELECT COUNT(*)
FROM customer

-- let's  find out who are our best customers, starting with 6 ways to define best:
--- a. revenue/total spending
SELECT
	first_name || ' ' || last_name AS customer,
	member_card,
	ROUND(revenue, 2) AS total_spending,
	ROUND(pct_revenue * 100, 2) AS pct_revenue,
	txn,
	homeowner,
	total_children,
	occupation,
	yearly_income
FROM (SELECT
	a.customer_id,
	revenue,
	pct_revenue,
	txn
FROM cte_2 a
JOIN transaction_2 b ON a.customer_id = b.customer_id
ORDER BY 2 DESC
LIMIT 5) a
JOIN customer b ON a.customer_id = b.customer_id
ORDER BY revenue DESC

-- b. quantity bought
SELECT
	first_name || ' ' || last_name AS customer_name,
	member_card,
	qty_bought,
	pct_bought,
	txn,
	homeowner,
	total_children,
	occupation,
	yearly_income
FROM (
SELECT
	a.customer_id,
	unit AS qty_bought,
	ROUND(pct_unit * 100, 2) As pct_bought
FROM cte_2 a
ORDER BY 2 DESC
LIMIT 5
) a
JOIN customer b ON a.customer_id = b.customer_id 
JOIN transaction_2 c ON a.customer_id = c.customer_id
ORDER BY qty_bought DESC

-- c. profit 
SELECT
	first_name || ' ' || last_name AS customer_name,
	member_card,
	ROUND(profit,2) AS profit,
	profit_margin,
	txn,
	homeowner,
	total_children,
	occupation,
	yearly_income
FROM (
SELECT
	a.customer_id,
	revenue,
	unit,
	profit,
	profit_margin
FROM cte_2 a
ORDER BY profit DESC
LIMIT 5
) a
JOIN customer b ON a.customer_id = b.customer_id 
JOIN transaction_2 c ON a.customer_id = c.customer_id
ORDER BY profit DESC

-- d. transaction
SELECT
	first_name || ' ' || last_name AS customer_name,
	member_card,
	txn,
	txn_perc,
	revenue,
	homeowner,
	total_children,
	occupation,
	yearly_income
FROM (
SELECT
	a.customer_id,
	txn,
	ROUND(txn/SUM(txn) OVER () * 100, 2) AS txn_perc
FROM transaction_2 a
ORDER BY txn DESC
LIMIT 5
) a
JOIN customer b ON a.customer_id = b.customer_id 
JOIN cte_2 c ON a.customer_id = c.customer_id
ORDER BY txn DESC

-- e. average transaction value
SELECT
	first_name || ' ' || last_name AS customer_name,
	member_card,
	a.revenue,
	txn,
	avg_transaction_value,
	homeowner,
	total_children,
	occupation,
	yearly_income
FROM (
SELECT
	a.customer_id,
	txn,
	revenue,
	ROUND(revenue/txn, 2) AS avg_transaction_value
FROM transaction_2 a
JOIN cte_2 b
ON a.customer_id = b.customer_id
ORDER BY avg_transaction_value DESC
LIMIT 5
) a
JOIN customer b ON a.customer_id = b.customer_id 
JOIN cte_2 c ON a.customer_id = c.customer_id
ORDER BY avg_transaction_value DESC


-- f. average basket size
SELECT
	first_name || ' ' || last_name AS customer_name,
	member_card,
	a.unit,
	txn,
	avg_basket_size,
	homeowner,
	total_children,
	occupation,
	yearly_income
FROM (
SELECT
	a.customer_id,
	txn,
	unit,
	ROUND(unit/txn, 2) AS avg_basket_size
FROM transaction_2 a
JOIN cte_2 b
ON a.customer_id = b.customer_id
ORDER BY avg_basket_size DESC
LIMIT 5
) a
JOIN customer b ON a.customer_id = b.customer_id 
JOIN cte_2 c ON a.customer_id = c.customer_id
ORDER BY avg_basket_size DESC


--------------- deeper dive into membership tiers ----------------------
-- how are all members divided based on membership tier?
SELECT
	member_card,
	member_count,
	ROUND(member_count/SUM(member_count) OVER () * 100, 2) AS member_perc,
	RANK() OVER (ORDER BY member_count DESC)
FROM (SELECT
	member_card,
	COUNT(*)::NUMERIC AS member_count
FROM customer
GROUP BY 1)
-- golden (assume it's the highest tier, is ranked 3rd, while silver is ranked last)
-- maybe members are having extra thinking when deciding to upgrade from bronze to silver


-- there's a difference in the members, considering some are not active, how are our customer engagement metrics looking 
-- active rate
SELECT
	x.member_card,
	y.member_count,
	active_member_count,
	active_member_pct,
	non_returning_member,
	non_returning_member_pct
FROM (
SELECT 
	a.member_card,
	member_count,
	active_member_count,
	ROUND(active_member_count/member_count * 100, 2) AS active_member_pct
FROM (
SELECT
	member_card,
	COUNT(*)::NUMERIC AS member_count
FROM customer
GROUP BY 1
) a
JOIN (
SELECT
	member_card,
	COUNT(*)::NUMERIC AS active_member_count
FROM cte_2 a
JOIN customer c ON a.customer_id = c.customer_id
GROUP BY 1
) b
ON a.member_card = b.member_card) x
JOIN (
-- non-returning rate
SELECT 
	a.member_card,
	member_count,
	non_returning_member,
	ROUND(non_returning_member/member_count * 100, 2) AS non_returning_member_pct
FROM (
SELECT
	member_card,
	COUNT(*)::NUMERIC AS member_count
FROM customer
GROUP BY 1
) a
JOIN (
SELECT 
	member_card,
	COUNT(txn) AS non_returning_member
FROM transaction_2 a
JOIN customer b ON a.customer_id = b.customer_id
WHERE txn = 1
GROUP BY 1
) b
ON a.member_card = b.member_card
) y
ON x.member_card = y.member_card


-- member tier: revenue per member
SELECT
	member_card,
	member_revenue,
	member_revenue_perc,
	RANK() OVER (ORDER BY member_revenue_perc DESC) AS member_revenue_rank,
	member_count,
	member_count_perc,
	revenue_per_member,
	RANK() OVER (ORDER BY revenue_per_member DESC) AS revenue_per_member_rank
FROM (
SELECT
	member_card,
	member_revenue,
	SUM(member_revenue) OVER () AS total_revenue,
	ROUND(member_revenue/SUM(member_revenue) OVER () * 100, 2) AS member_revenue_perc,
	member_count,
	SUM(member_count) OVER () AS total_active_customers,
	ROUND(member_count/SUM(member_count) OVER () * 100, 2) As member_count_perc,
	ROUND(member_revenue/member_count) AS revenue_per_member
FROM (
SELECT
	member_card,
	ROUND(SUM(revenue), 2) AS member_revenue,
	COUNT(c.customer_id) As member_count
FROM cte_2 a
JOIN customer c ON a.customer_id = c.customer_id
GROUP BY 1
ORDER BY 2 DESC
) 
)

-- member tier: transaction per member
SELECT
	member_card,
	member_txn,
	member_txn_perc,
	RANK() OVER (ORDER BY member_txn_perc DESC) AS member_txn_rank,
	member_count,
	member_count_perc,
	txn_per_member,
	RANK() OVER (ORDER BY txn_per_member DESC) AS txn_per_member_rank
FROM (
SELECT
	member_card,
	member_txn,
	SUM(member_txn) OVER () AS total_txn,
	ROUND(member_txn/SUM(member_txn) OVER () * 100, 2) AS member_txn_perc,
	member_count,
	SUM(member_count) OVER () AS total_active_customers,
	ROUND(member_count/SUM(member_count) OVER () * 100, 2) As member_count_perc,
	ROUND(member_txn/member_count,2) AS txn_per_member
FROM (
SELECT
	member_card,
	SUM(txn) AS member_txn,
	COUNT(a.customer_id) AS member_count
FROM transaction_2 a
JOIN customer c ON a.customer_id = c.customer_id
GROUP BY 1
ORDER BY 2 DESC
) 
)

-- member tier: profit per member
SELECT
	member_card,
	member_profit,
	member_profit_perc,
	RANK() OVER (ORDER BY member_profit_perc DESC) AS member_profit_rank,
	member_count,
	member_count_perc,
	profit_per_member,
	RANK() OVER (ORDER BY profit_per_member DESC) AS profit_per_member_rank
FROM (
SELECT
	member_card,
	member_profit,
	SUM(member_profit) OVER () AS total_profit,
	ROUND(member_profit/SUM(member_profit) OVER () * 100, 2) AS member_profit_perc,
	member_count,
	SUM(member_count) OVER () AS total_active_customers,
	ROUND(member_count/SUM(member_count) OVER () * 100, 2) As member_count_perc,
	ROUND(member_profit/member_count,2) AS profit_per_member
FROM (
SELECT
	member_card,
	ROUND(SUM(profit), 2) AS member_profit,
	COUNT(a.customer_id) AS member_count
FROM cte_2 a
JOIN customer c ON a.customer_id = c.customer_id
GROUP BY 1
ORDER BY 2 DESC
) 
)

-- member tier: profit margin 
SELECT
	member_card,
	member_profit_margin,
	RANK() OVER (ORDER BY member_profit_margin DESC) AS profit_margin_member_rank
FROM (
SELECT
	member_card,
	ROUND(AVG(profit_margin), 2) AS member_profit_margin
FROM cte_2 a
JOIN customer c ON a.customer_id = c.customer_id
GROUP BY 1
ORDER BY 2 DESC
) 


-- member tier: quantity bought per member
SELECT
	member_card,
	member_qty_bought,
	member_qty_bought_perc,
	RANK() OVER (ORDER BY member_qty_bought_perc DESC) AS member_qty_bought_rank,
	member_count,
	member_count_perc,
	qty_bought_per_member,
	RANK() OVER (ORDER BY qty_bought_per_member DESC) AS qty_bought_per_member_rank
FROM (
SELECT
	member_card,
	member_qty_bought,
	SUM(member_qty_bought) OVER () AS total_profit,
	ROUND(member_qty_bought/SUM(member_qty_bought) OVER () * 100, 2) AS member_qty_bought_perc,
	member_count,
	SUM(member_count) OVER () AS total_active_customers,
	ROUND(member_count/SUM(member_count) OVER () * 100, 2) As member_count_perc,
	ROUND(member_qty_bought/member_count,2) AS qty_bought_per_member
FROM (
SELECT
	member_card,
	SUM(unit) AS member_qty_bought,
	COUNT(a.customer_id) AS member_count
FROM cte_2 a
JOIN customer c ON a.customer_id = c.customer_id
GROUP BY 1
ORDER BY 2 DESC
) 
)

-- member tier: average basket size & average transaction value
SELECT
	a.member_card,
	ROUND(member_qty_bought/member_txn, 2) AS avg_basket_size,
	RANK() OVER (ORDER BY member_qty_bought/member_txn DESC) AS avg_basket_size_rank,
	member_total_spending/member_txn AS avg_txn_value,
	RANK() OVER (ORDER BY member_total_spending/member_txn) AS avg_txn_value_rank
FROM (
SELECT
	member_card,
	SUM(unit) AS member_qty_bought,
	SUM(revenue) AS member_total_spending,
	COUNT(a.customer_id) AS member_count
FROM cte_2 a
JOIN customer c ON a.customer_id = c.customer_id
GROUP BY 1
ORDER BY 2 DESC
) a
JOIN (
SELECT
	member_card,
	SUM(txn) AS member_txn,
	COUNT(a.customer_id) AS member_count
FROM transaction_2 a
JOIN customer c ON a.customer_id = c.customer_id
GROUP BY 1
ORDER BY 2 DESC
) b
ON a.member_card = b.member_card


-- who are our most frequent spenders => Golden member have higher rate of transaction per member than any other tier, even surpassing bronze tier with members almost 5x 
-- transaction per member tier
SELECT
	member_card,
	member_txn,
	member_count,
	txn_per_member,
	SUM(member_txn) OVER () AS total_txn,
	AVG(member_txn) OVER () AS avg_txn
FROM (
SELECT
	member_card,
	SUM(txn) AS member_txn,
	COUNT(member_card) AS member_count,
	ROUND(AVG(txn),2) AS txn_per_member
FROM (
SELECT
	member_card,
	a.txn,
	a.avg_txn,
	SUM(txn) OVER () AS total_txn,
	max_txn,
	min_txn
FROM transaction_2 a
JOIN customer b
ON a.customer_id = b.customer_id
) a
GROUP BY 1
ORDER BY 2
)


-- average days between transaction
SELECT
	member_card,
	ROUND(AVG(avg_dur_cust),0) AS avg_dur_member
FROM (
SELECT
	a.customer_id,
	member_card,
	ROUND(AVG(duration),0) AS avg_dur_cust
FROM (
SELECT 
	customer_id,
	txn_date,
	LAG(txn_date,1) OVER 
	(PARTITION BY customer_id ORDER BY txn_date),
	txn_date - LAG(txn_date,1) OVER 
	(PARTITION BY customer_id ORDER BY txn_date) AS duration
FROM (
SELECT
	DISTINCT transaction_date::DATE AS txn_date,
	customer_id
FROM store_performance
GROUP BY 1,2
ORDER BY 2
)
) a
JOIN customer b ON a.customer_id = b.customer_id
GROUP BY 1, 2
HAVING AVG(duration) IS NOT NULL
)
GROUP BY 1

-- member transaction_value over the months
WITH member_monthly_spend AS (
SELECT
	txn_month,
	member_card,
	spending,
	RANK() OVER (PARTITION BY txn_month ORDER BY spending),
	SUM(spending) OVER (PARTITION BY txn_month ORDER BY txn_month) AS monthly_spend
FROM (
SELECT
	txn_month,
	member_card,
	SUM(spending) AS spending
FROM (
SELECT
	EXTRACT(MONTH FROM txn_date) AS txn_month,
	member_card,
	spending
FROM (
SELECT
	DISTINCT(transaction_date) AS txn_date,
	a.customer_id,
	c.member_card,
	ROUND(SUM(quantity * product_retail_price)::NUMERIC, 2) AS spending
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
LEFT JOIN customer c
ON a.customer_id = c.customer_id
GROUP BY 1, 2, 3
ORDER BY 2
)
ORDER BY 1,2
)
GROUP BY 1,2
)
),
member_monthly_txn AS (
SELECT
	txn_month,
	member_card,
	txn,
	RANK() OVER (PARTITION BY txn_month ORDER BY txn DESC)
FROM (
SELECT
	EXTRACT(MONTH FROM txn_date) AS txn_month,
	member_card,
	COUNT(*)::NUMERIC AS txn
FROM (
SELECT
	DISTINCT(transaction_date) AS txn_date,
	a.customer_id,
	c.member_card
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
LEFT JOIN customer c
ON a.customer_id = c.customer_id
GROUP BY 1, 2, 3
ORDER BY 2
)
GROUP BY 1, 2
ORDER BY 1, 2
)
)

SELECT
	txn_month,
	member_card,
	spending,
	txn,
	avg_txn_value,
	RANK() OVER (PARTITION BY txn_month ORDER BY avg_txn_value) AS rank
FROM (
SELECT
	a.txn_month,
	a.member_card,
	spending,
	txn,
	ROUND(spending/txn) AS avg_txn_value
FROM member_monthly_spend a
JOIN member_monthly_txn b
ON a.txn_month = b.txn_month
AND a.member_card = b.member_card
)


-- member profit margin over the months
SELECT
	txn_month,
	member_card,
	profit_margin,
	RANK() OVER (PARTITION BY txn_month ORDER BY profit_margin DESC),
	ROUND(AVG(profit_margin) OVER (PARTITION BY txn_month ORDER BY txn_month),3) AS monthly_profit_margin
FROM (
SELECT
	txn_month,
	member_card,
	ROUND(AVG(profit_margin),2) AS profit_margin
FROM (
SELECT
	EXTRACT(MONTH FROM txn_date) AS txn_month,
	member_card,
	spending,
	ROUND(profit/spending*100, 2) AS profit_margin
FROM (
SELECT
	DISTINCT(transaction_date) AS txn_date,
	a.customer_id,
	c.member_card,
	ROUND(SUM(quantity * product_retail_price)::NUMERIC,2) AS spending,
	ROUND((SUM(quantity * product_retail_price)-SUM(quantity * product_cost))
	::NUMERIC, 2) AS profit
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
LEFT JOIN customer c
ON a.customer_id = c.customer_id
GROUP BY 1, 2, 3
ORDER BY 2
)
ORDER BY 1,2
)
GROUP BY 1,2
)


-- hard: first vs returning transaction mix over the months 
-- all customers' first transaction dates
WITH first_txn AS (
SELECT
	DATE_TRUNC('month', first_txn)::DATE AS first_txn_month,
	COUNT(cust) AS first_txn
FROM (
SELECT
	DISTINCT(customer_id) AS cust,
	MIN(transaction_date)::DATE AS first_txn
FROM store_performance
GROUP BY 1
)
GROUP BY 1
ORDER BY 1
),
-- logic check => 1396 rows
/*SELECT
	cust
FROM (
SELECT
	DISTINCT(customer_id) AS cust,
	MIN(transaction_date)::DATE AS first_txn
FROM store_performance
GROUP BY 1
)
WHERE first_txn BETWEEN '1997-01-01' AND '1997-01-31'*/


-- all customers' returning transaction dates
return_txn AS (
SELECT
	DATE_TRUNC('month', txn_date)::DATE As return_txn_month,
	COUNT(cust) AS return_txn
FROM (
SELECT
	cust,
	txn_date,
	MIN(txn_date) OVER (PARTITION BY cust ORDER BY txn_date) AS first_txn
FROM (
SELECT
	DISTINCT customer_id AS cust,
	transaction_date::DATE AS txn_date
FROM store_performance a
GROUP BY 1, 2
ORDER BY 1
)
)
WHERE txn_date <> first_txn
GROUP BY 1
ORDER BY 1
)

-- logic check: returning customers on the first month = bought >1x on the same month
/*SELECT
	DATE_TRUNC('month', txn_date)::DATE As return_txn,
	COUNT(cust) AS cust
FROM (
SELECT
	cust,
	txn_date,
	MIN(txn_date) OVER (PARTITION BY cust ORDER BY txn_date) AS first_txn
FROM (
SELECT
	DISTINCT customer_id AS cust,
	transaction_date::DATE AS txn_date
FROM store_performance a
GROUP BY 1, 2
ORDER BY 1
)
WHERE txn_date BETWEEN '1997-01-01' AND '1997-01-31'
)
WHERE txn_date <> first_txn
GROUP BY 1
ORDER BY 1*/

-- new vs returning mix
SELECT 
	first_txn_month,
	first_txn,
	return_txn
FROM first_txn a
JOIN return_txn b
ON a.first_txn_month = b.return_txn_month

-- all customer open new accounts
SELECT
	acct_open_month,
	COUNT(customer_id)
FROM(
SELECT
	customer_id,
	DATE_TRUNC('month', acct_open_date)::DATE AS acct_open_month
FROM customer
)
GROUP BY 1
ORDER BY 1

-- active customers' open acct months
SELECT
	acct_open_month,
	COUNT(customer_id)
FROM (
SELECT
	DISTINCT a.customer_id,
	DATE_TRUNC('month', acct_open_date)::DATE AS acct_open_month
FROM store_performance a
LEFT JOIN customer b
ON a.customer_id = b.customer_id
)
GROUP BY 1
ORDER BY 1




-- monthly active customers by tier 
SELECT
	txn_month,
	member_card,
	active_cust,
	SUM(active_cust) OVER (PARTITION BY txn_month ORDER BY txn_month) AS monthly_active_cust
FROM (
SELECT
	EXTRACT(MONTH FROM txn_date) AS txn_month,
	member_card,
	COUNT(DISTINCT customer_id)::NUMERIC AS active_cust
FROM (
SELECT
	DISTINCT(transaction_date) AS txn_date,
	a.customer_id,
	c.member_card
FROM store_performance a
LEFT JOIN store_products b
ON a.product_id = b.product_id
LEFT JOIN customer c
ON a.customer_id = c.customer_id
GROUP BY 1, 2, 3
ORDER BY 2
)
GROUP BY 1, 2
ORDER BY 1, 2
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



