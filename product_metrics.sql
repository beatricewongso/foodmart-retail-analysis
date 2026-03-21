WITH fact AS (
	SELECT
		COUNT(product_id):: NUMERIC AS total_products,
		COUNT(DISTINCT product_brand):: NUMERIC AS total_brands,
		AVG(product_retail_price):: NUMERIC AS avg_price,
		AVG(product_cost):: NUMERIC AS avg_cost,
		SUM(recyclable::INT)::NUMERIC AS recyclable,
		SUM(low_fat::INT)::NUMERIC AS low_fat
	FROM store_products a
), 
sold AS (
	SELECT
	COUNT(DISTINCT product_id):: NUMERIC AS sold_products,
	COUNT(DISTINCT product_brand):: NUMERIC AS sold_brands
	FROM (
		SELECT
			a.product_id,
			b.product_brand
		FROM store_performance a
		LEFT JOIN store_products b 
		ON a.product_id = b.product_id
		)
),
gen AS (
	SELECT
		SUM(quantity):: NUMERIC AS units,
		SUM(quantity * product_retail_price):: NUMERIC AS rev
	FROM store_performance a
	LEFT JOIN store_products b
	ON a.product_id = b.product_id
),
lowfat_and_recyclable AS (
	SELECT
		COUNT(*)::NUMERIC AS both_low
	FROM store_products
	WHERE low_fat::INT = 1
	AND recyclable::INT = 1
)

SELECT
	ROUND(sold_products/total_products*100,2) AS unique_products_sold_pct,
	ROUND(sold_brands/total_brands*100,2) AS unique_brands_sold_pct,
	ROUND(units/sold_products,0) AS avg_product_qty_sold,
	ROUND(units/sold_brands,0) AS avg_brand_qty_sold,
	ROUND(rev/units,2) AS avg_selling_price,
	ROUND(avg_price/avg_cost*100,2) AS avg_markup_pct,
	ROUND(recyclable/total_products*100,2) AS recyclable_pct,
	ROUND(low_fat/total_products*100,2) AS low_fat_pct,
	ROUND(both_low/total_products*100,2) AS both_recyable_lowfat_pct
FROM fact
CROSS JOIN sold
CROSS JOIN gen
CROSS JOIN lowfat_and_recyclable
	


