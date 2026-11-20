/*==============================================================
    Project  : SQL Advanced Data Analytics - Bike Sales (gold layer)
    Author   : Aman Nakhate
    Database : MySQL 8.0+  (CTEs and window functions are used)
    Tables   : gold.dim_customers, gold.dim_products, gold.fact_sales

    Sections
      1. Database / dimensions / date exploration   (Q1  - Q10)
      2. Measures and KPIs                          (Q11 - Q19)
      3. Magnitude and ranking analysis             (Q20 - Q41)
      4. Data quality checks                        (Q42 - Q43)
      5. Change over time and cumulative analysis   (Q44 - Q48)
      6. Performance analysis (YoY)                 (Q49 - Q50)
      7. Part-to-whole analysis                     (Q51 - Q54)
      8. Data segmentation                          (Q55 - Q56)
      9. Customer and product report views          (Q57 - Q62)
==============================================================*/

USE gold;


/*==============================================================
                    DATABASE EXPLORATION
==============================================================*/

-- Q1. What tables and views exist in the current database?
SELECT
    TABLE_SCHEMA AS database_name,
    TABLE_NAME   AS object_name,
    TABLE_TYPE   AS object_type
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'gold'
ORDER BY TABLE_SCHEMA, TABLE_NAME;


-- Q2. What columns exist in the database?
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    ORDINAL_POSITION,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'
ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;


-- Q3. What columns are present in the customer dimension?
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'
  AND TABLE_NAME = 'dim_customers'
ORDER BY ORDINAL_POSITION;


/*==============================================================
                    DIMENSIONS EXPLORATION
==============================================================*/

-- Q4. Which countries do customers come from?
SELECT DISTINCT country
FROM gold.dim_customers
ORDER BY country;


-- Q5. Which product categories exist?
SELECT DISTINCT category
FROM gold.dim_products
ORDER BY category;


-- Q6. What category, subcategory, and product hierarchy exists?
SELECT DISTINCT
    category,
    subcategory,
    product_name
FROM gold.dim_products
ORDER BY category, subcategory, product_name;


/*==============================================================
                    DATE EXPLORATION
==============================================================*/

-- Q7. What are the first and last order dates?
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM gold.fact_sales;


-- Q8. How many years and months of order history are available?
SELECT
    TIMESTAMPDIFF(YEAR,  MIN(order_date), MAX(order_date)) AS order_range_years,
    TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS order_range_months
FROM gold.fact_sales;


-- Q9. What are the oldest and youngest customers' birth dates?
SELECT
    MIN(birthdate) AS oldest_birthdate,
    MAX(birthdate) AS youngest_birthdate
FROM gold.dim_customers;


-- Q10. What are the oldest and youngest customers' approximate ages?
SELECT
    TIMESTAMPDIFF(YEAR, MIN(birthdate), CURDATE()) AS oldest_age_approx,
    TIMESTAMPDIFF(YEAR, MAX(birthdate), CURDATE()) AS youngest_age_approx
FROM gold.dim_customers;


/*==============================================================
                    MEASURES EXPLORATION / KPI
==============================================================*/

-- Q11. What is the total sales revenue?
SELECT SUM(sales_amount) AS total_sales
FROM gold.fact_sales;


-- Q12. How many items have been sold in total?
SELECT SUM(quantity) AS total_quantity
FROM gold.fact_sales;


-- Q13. What is the average selling price?
SELECT AVG(price) AS average_price
FROM gold.fact_sales;


-- Q14. How many sales rows/order-line records are there?
SELECT COUNT(order_number) AS sales_rows_or_order_lines
FROM gold.fact_sales;


-- Q15. How many unique orders are there?
SELECT COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales;


-- Q16. How many products are in the product dimension?
SELECT COUNT(product_key) AS total_products
FROM gold.dim_products;


-- Q17. How many customers are registered?
SELECT COUNT(customer_key) AS total_customers
FROM gold.dim_customers;


-- Q18. How many distinct customers have placed an order?
SELECT COUNT(DISTINCT customer_key) AS customers_who_ordered
FROM gold.fact_sales;


-- Q19. Consolidated KPI Report
SELECT 'Total Sales' AS measure_name,
       SUM(sales_amount) AS measure_value
FROM gold.fact_sales

UNION ALL

SELECT 'Total Quantity',
       SUM(quantity)
FROM gold.fact_sales

UNION ALL

SELECT 'Average Price',
       AVG(price)
FROM gold.fact_sales

UNION ALL

SELECT 'Order Lines (count)',
       COUNT(order_number)
FROM gold.fact_sales

UNION ALL

SELECT 'Unique Orders',
       COUNT(DISTINCT order_number)
FROM gold.fact_sales

UNION ALL

SELECT 'Total Products',
       COUNT(product_key)
FROM gold.dim_products

UNION ALL

SELECT 'Total Customers',
       COUNT(customer_key)
FROM gold.dim_customers

UNION ALL

SELECT 'Customers Who Ordered',
       COUNT(DISTINCT customer_key)
FROM gold.fact_sales;


/*==============================================================
                    MAGNITUDE ANALYSIS
==============================================================*/




-- Q20. How many customers are there by gender?
SELECT
    gender,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- Q21. How many customers are there in each country?
SELECT
    country,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;


-- Q22. How many products are there in each category?
SELECT
    category,
    COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;


-- Q23. What is the average product cost for each category?
SELECT
    category,
    AVG(cost) AS average_cost
FROM gold.dim_products
GROUP BY category
ORDER BY average_cost DESC;


-- Q24. What is total revenue for each product category?
SELECT
    p.category,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;


-- Q25. How many items were sold in each country?
SELECT
    c.country,
    SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC;

-- Q26. What is total revenue generated by each customer?
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_revenue DESC;



/*==============================================================
                    RANKING ANALYSIS
==============================================================*/

-- Q27. Find the Top 5 Products by Revenue
SELECT
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY
    p.product_name
ORDER BY
    total_revenue DESC
LIMIT 5;


-- Q28. Find the Bottom 5 Products by Revenue
SELECT
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY
    p.product_name
ORDER BY
    total_revenue ASC
LIMIT 5;


-- Q29. Find the Top 5 Subcategories by Revenue
SELECT
    p.subcategory,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY
    p.subcategory
ORDER BY
    total_revenue DESC
LIMIT 5;


-- Q30. Find the Bottom 5 Subcategories by Revenue
SELECT
    p.subcategory,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY
    p.subcategory
ORDER BY
    total_revenue ASC
LIMIT 5;


-- Q31. Rank Products by Revenue using ROW_NUMBER()
-- Return the Top 5 Products
SELECT *
FROM
(
    SELECT
        p.product_name,
        SUM(f.sales_amount) AS total_revenue,

        ROW_NUMBER() OVER (
            ORDER BY SUM(f.sales_amount) DESC
        ) AS rank_products

    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key

    GROUP BY
        p.product_name
) AS ranked_products

WHERE rank_products <= 5

ORDER BY
    rank_products;


-- Q32. Find the Top 10 Customers by Revenue
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY
    total_revenue DESC
LIMIT 10;


-- Q33. Find the 3 Customers with the Fewest Orders
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT f.order_number) AS total_orders
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY
    total_orders ASC
LIMIT 3;


/*==============================================================
                    RANKING EXPLORATION
==============================================================*/

-- Q34. Rank All Products by Revenue
SELECT
    p.product_name,
    SUM(f.sales_amount) AS total_revenue,

    ROW_NUMBER() OVER (
        ORDER BY SUM(f.sales_amount) DESC
    ) AS row_num,

    RANK() OVER (
        ORDER BY SUM(f.sales_amount) DESC
    ) AS product_rank,

    DENSE_RANK() OVER (
        ORDER BY SUM(f.sales_amount) DESC
    ) AS product_dense_rank

FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key

GROUP BY
    p.product_name

ORDER BY
    total_revenue DESC;


-- Q35. Find the Top 10 Products by Quantity Sold
SELECT
    p.product_name,
    SUM(f.quantity) AS total_quantity
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY
    p.product_name
ORDER BY
    total_quantity DESC
LIMIT 10;


-- Q36. Find the Bottom 10 Products by Quantity Sold
SELECT
    p.product_name,
    SUM(f.quantity) AS total_quantity
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY
    p.product_name
ORDER BY
    total_quantity ASC
LIMIT 10;


-- Q37. Find the Top 5 Customers by Number of Orders
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT f.order_number) AS total_orders
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY
    total_orders DESC
LIMIT 5;


-- Q38. Rank Customers by Revenue
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_revenue,

    ROW_NUMBER() OVER (
        ORDER BY SUM(f.sales_amount) DESC
    ) AS customer_rank

FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key

GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name

ORDER BY
    total_revenue DESC;


-- Q39. Find the Top 3 Products in Each Category
WITH ranked_products AS
(
    SELECT
        p.category,
        p.product_name,
        SUM(f.sales_amount) AS total_revenue,

        ROW_NUMBER() OVER (
            PARTITION BY p.category
            ORDER BY SUM(f.sales_amount) DESC
        ) AS rank_in_category

    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key

    GROUP BY
        p.category,
        p.product_name
)

SELECT
    category,
    product_name,
    total_revenue,
    rank_in_category
FROM ranked_products
WHERE rank_in_category <= 3
ORDER BY
    category,
    rank_in_category;


-- Q40. Find the Top 5 Countries by Revenue
SELECT
    c.country,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY
    c.country
ORDER BY
    total_revenue DESC
LIMIT 5;

-- Q41 . Find the Top 5 Countries by lowest Revenue

SELECT
    c.country,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY
    c.country
ORDER BY
    total_revenue ASC
LIMIT 5;


/*==============================================================
                    DATA QUALITY CHECKS
==============================================================*/

-- Q42. Missing values that can affect the analysis
-- (19 order lines have no order_date, so every time-based query below filters them out)
SELECT 'fact_sales  : order_date missing' AS check_name, COUNT(*) AS rows_affected
FROM gold.fact_sales
WHERE order_date IS NULL
UNION ALL
SELECT 'dim_customers : country missing', COUNT(*)
FROM gold.dim_customers
WHERE country IS NULL OR TRIM(country) = ''
UNION ALL
SELECT 'dim_customers : gender missing', COUNT(*)
FROM gold.dim_customers
WHERE gender IS NULL OR TRIM(gender) = ''
UNION ALL
SELECT 'dim_customers : birthdate missing', COUNT(*)
FROM gold.dim_customers
WHERE birthdate IS NULL
UNION ALL
SELECT 'dim_products  : category missing', COUNT(*)
FROM gold.dim_products
WHERE category IS NULL OR TRIM(category) = '';


-- Q43. Any sales rows that do not match a product or a customer?
SELECT
    SUM(CASE WHEN p.product_key  IS NULL THEN 1 ELSE 0 END) AS orphan_products,
    SUM(CASE WHEN c.customer_key IS NULL THEN 1 ELSE 0 END) AS orphan_customers
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products  AS p ON f.product_key  = p.product_key
LEFT JOIN gold.dim_customers AS c ON f.customer_key = c.customer_key;


/*==============================================================
                    CHANGE OVER TIME
==============================================================*/

-- Q44. Yearly sales, customers and quantity
-- note: 2010 (only Dec) and 2014 (only Jan) are partial years
SELECT
    YEAR(order_date)               AS order_year,
    SUM(sales_amount)              AS total_sales,
    COUNT(DISTINCT customer_key)   AS total_customers,
    SUM(quantity)                  AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY order_year;


-- Q45. Monthly sales trend
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    SUM(sales_amount)                AS total_sales,
    COUNT(DISTINCT customer_key)     AS total_customers,
    SUM(quantity)                    AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;


-- Q46. Seasonality - which calendar month sells the most (all years together)
SELECT
    MONTH(order_date)  AS month_number,
    MONTHNAME(order_date) AS month_name,
    SUM(sales_amount)  AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY MONTH(order_date), MONTHNAME(order_date)
ORDER BY month_number;


/*==============================================================
                    CUMULATIVE ANALYSIS
==============================================================*/

-- Q47. Running total of monthly sales and moving average of price
SELECT
    order_month,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_month)          AS running_total_sales,
    ROUND(AVG(avg_price) OVER (ORDER BY order_month), 2)  AS moving_avg_price
FROM
(
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS order_month,
        SUM(sales_amount)                AS total_sales,
        AVG(price)                       AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
) AS monthly_sales
ORDER BY order_month;


-- Q48. Running total that restarts every year (year-to-date sales)
SELECT
    order_year,
    order_month,
    total_sales,
    SUM(total_sales) OVER (
        PARTITION BY order_year
        ORDER BY order_month
    ) AS ytd_sales
FROM
(
    SELECT
        YEAR(order_date)                 AS order_year,
        DATE_FORMAT(order_date, '%Y-%m') AS order_month,
        SUM(sales_amount)                AS total_sales
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY YEAR(order_date), DATE_FORMAT(order_date, '%Y-%m')
) AS monthly_sales
ORDER BY order_year, order_month;


/*==============================================================
                    PERFORMANCE ANALYSIS
==============================================================*/

-- Q49. Year-over-year growth in total sales
-- 2013 vs 2012 is the only fair comparison (2010 and 2014 are partial years)
WITH yearly_sales AS
(
    SELECT
        YEAR(order_date)  AS order_year,
        SUM(sales_amount) AS current_sales
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY YEAR(order_date)
)
SELECT
    order_year,
    current_sales,
    LAG(current_sales) OVER (ORDER BY order_year) AS previous_year_sales,
    current_sales - LAG(current_sales) OVER (ORDER BY order_year) AS difference,
    ROUND(
        (current_sales - LAG(current_sales) OVER (ORDER BY order_year))
        / NULLIF(LAG(current_sales) OVER (ORDER BY order_year), 0) * 100
    , 2) AS yoy_growth_pct
FROM yearly_sales
ORDER BY order_year;


-- Q50. Yearly performance of every product
-- compared with the product's own average and with the previous year
WITH yearly_product_sales AS
(
    SELECT
        YEAR(f.order_date)  AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY YEAR(f.order_date), p.product_name
)
SELECT
    order_year,
    product_name,
    current_sales,
    ROUND(AVG(current_sales) OVER (PARTITION BY product_name), 0) AS avg_sales,
    current_sales - ROUND(AVG(current_sales) OVER (PARTITION BY product_name), 0) AS diff_from_avg,
    CASE
        WHEN current_sales > AVG(current_sales) OVER (PARTITION BY product_name) THEN 'Above Avg'
        WHEN current_sales < AVG(current_sales) OVER (PARTITION BY product_name) THEN 'Below Avg'
        ELSE 'Avg'
    END AS avg_flag,
    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS previous_year_sales,
    current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_from_py,
    CASE
        WHEN current_sales > LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) THEN 'Increase'
        WHEN current_sales < LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) THEN 'Decrease'
        ELSE 'No Change'
    END AS py_flag
FROM yearly_product_sales
ORDER BY product_name, order_year;


/*==============================================================
                    PART-TO-WHOLE ANALYSIS
==============================================================*/

-- Q51. Which category contributes the most to total sales?
WITH category_sales AS
(
    SELECT
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    GROUP BY p.category
)
SELECT
    category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,
    ROUND(total_sales / SUM(total_sales) OVER () * 100, 2) AS pct_of_total
FROM category_sales
ORDER BY total_sales DESC;


-- Q52. Share of total sales by country
WITH country_sales AS
(
    SELECT
        c.country,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_customers AS c
        ON f.customer_key = c.customer_key
    GROUP BY c.country
)
SELECT
    country,
    total_sales,
    ROUND(total_sales / SUM(total_sales) OVER () * 100, 2) AS pct_of_total
FROM country_sales
ORDER BY total_sales DESC;


-- Q53. Share of total sales by subcategory (top 10)
WITH subcategory_sales AS
(
    SELECT
        p.subcategory,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    GROUP BY p.subcategory
)
SELECT
    subcategory,
    total_sales,
    ROUND(total_sales / SUM(total_sales) OVER () * 100, 2) AS pct_of_total
FROM subcategory_sales
ORDER BY total_sales DESC
LIMIT 10;


-- Q54. Category share inside every year
SELECT
    order_year,
    category,
    total_sales,
    ROUND(total_sales / SUM(total_sales) OVER (PARTITION BY order_year) * 100, 2) AS pct_of_year
FROM
(
    SELECT
        YEAR(f.order_date)  AS order_year,
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY YEAR(f.order_date), p.category
) AS yearly_category
ORDER BY order_year, total_sales DESC;


/*==============================================================
                    DATA SEGMENTATION
==============================================================*/

-- Q55. Group products into cost ranges
SELECT
    cost_range,
    COUNT(product_key) AS total_products
FROM
(
    SELECT
        product_key,
        CASE
            WHEN cost < 100               THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 501 AND 1000 THEN '501-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM gold.dim_products
) AS product_ranges
GROUP BY cost_range
ORDER BY total_products DESC;


-- Q56. Customer segments based on spending and history
--   VIP     : 12+ months of history and spent more than 5,000
--   Regular : 12+ months of history and spent 5,000 or less
--   New     : less than 12 months of history
WITH customer_spending AS
(
    SELECT
        f.customer_key,
        SUM(f.sales_amount) AS total_spending,
        TIMESTAMPDIFF(MONTH, MIN(f.order_date), MAX(f.order_date)) AS lifespan_months
    FROM gold.fact_sales AS f
    WHERE f.order_date IS NOT NULL
    GROUP BY f.customer_key
)
SELECT
    customer_segment,
    COUNT(customer_key)  AS total_customers,
    SUM(total_spending)  AS total_sales
FROM
(
    SELECT
        customer_key,
        total_spending,
        CASE
            WHEN lifespan_months >= 12 AND total_spending > 5000  THEN 'VIP'
            WHEN lifespan_months >= 12 AND total_spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM customer_spending
) AS segmented
GROUP BY customer_segment
ORDER BY total_customers DESC;


/*==============================================================
                    CUSTOMER REPORT (VIEW)
==============================================================*/
/*
   gold.report_customers
   - one row per customer
   - age group, segment (VIP / Regular / New)
   - recency, orders, sales, quantity, products, lifespan
   - avg order value and avg monthly spend
   The "as of" date is the last order in the data, not today's date.
*/

CREATE OR REPLACE VIEW gold.report_customers AS
WITH base_query AS
(
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        TIMESTAMPDIFF(YEAR, c.birthdate, (SELECT MAX(order_date) FROM gold.fact_sales)) AS age
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_customers AS c
        ON f.customer_key = c.customer_key
    WHERE f.order_date IS NOT NULL
),
customer_aggregation AS
(
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount)            AS total_sales,
        SUM(quantity)                AS total_quantity,
        COUNT(DISTINCT product_key)  AS total_products,
        MAX(order_date)              AS last_order_date,
        TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan_months
    FROM base_query
    GROUP BY customer_key, customer_number, customer_name, age
)
SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    CASE
        WHEN age IS NULL THEN 'Unknown'
        WHEN age < 20    THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,
    CASE
        WHEN lifespan_months >= 12 AND total_sales > 5000  THEN 'VIP'
        WHEN lifespan_months >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,
    last_order_date,
    TIMESTAMPDIFF(MONTH, last_order_date, (SELECT MAX(order_date) FROM gold.fact_sales)) AS recency_months,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan_months,
    ROUND(total_sales / NULLIF(total_orders, 0), 2) AS avg_order_value,
    ROUND(
        CASE WHEN lifespan_months = 0 THEN total_sales
             ELSE total_sales / lifespan_months
        END
    , 2) AS avg_monthly_spend
FROM customer_aggregation;


/*==============================================================
                    PRODUCT REPORT (VIEW)
==============================================================*/
/*
   gold.report_products
   - one row per product
   - category, subcategory, cost
   - segment (High / Mid / Low performer) based on total sales
   - recency, orders, sales, quantity, customers, lifespan
   - avg order revenue and avg monthly revenue
*/

CREATE OR REPLACE VIEW gold.report_products AS
WITH base_query AS
(
    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
),
product_aggregation AS
(
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan_months,
        MAX(order_date)                AS last_sale_date,
        COUNT(DISTINCT order_number)   AS total_orders,
        COUNT(DISTINCT customer_key)   AS total_customers,
        SUM(sales_amount)              AS total_sales,
        SUM(quantity)                  AS total_quantity,
        ROUND(AVG(sales_amount / NULLIF(quantity, 0)), 1) AS avg_selling_price
    FROM base_query
    GROUP BY product_key, product_name, category, subcategory, cost
)
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    TIMESTAMPDIFF(MONTH, last_sale_date, (SELECT MAX(order_date) FROM gold.fact_sales)) AS recency_months,
    CASE
        WHEN total_sales > 50000  THEN 'High Performer'
        WHEN total_sales >= 10000 THEN 'Mid Range'
        ELSE 'Low Performer'
    END AS product_segment,
    lifespan_months,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,
    ROUND(total_sales / NULLIF(total_orders, 0), 2) AS avg_order_revenue,
    ROUND(
        CASE WHEN lifespan_months = 0 THEN total_sales
             ELSE total_sales / lifespan_months
        END
    , 2) AS avg_monthly_revenue
FROM product_aggregation;


/*==============================================================
                    USING THE REPORTS
==============================================================*/

-- Q57. How are VIP, Regular and New customers performing?
SELECT
    customer_segment,
    COUNT(customer_key)              AS total_customers,
    SUM(total_sales)                 AS total_sales,
    ROUND(AVG(avg_order_value), 2)   AS avg_order_value,
    ROUND(SUM(total_sales) / SUM(SUM(total_sales)) OVER () * 100, 2) AS pct_of_sales
FROM gold.report_customers
GROUP BY customer_segment
ORDER BY total_sales DESC;


-- Q58. Top 10 customers with segment and age group
SELECT
    customer_key,
    customer_name,
    age_group,
    customer_segment,
    total_orders,
    total_sales
FROM gold.report_customers
ORDER BY total_sales DESC
LIMIT 10;


-- Q59. Customers by age group
SELECT
    age_group,
    COUNT(customer_key) AS total_customers,
    SUM(total_sales)    AS total_sales
FROM gold.report_customers
GROUP BY age_group
ORDER BY total_sales DESC;


-- Q60. Product segments - how many products and how much revenue
SELECT
    product_segment,
    COUNT(product_key) AS total_products,
    SUM(total_sales)   AS total_sales,
    ROUND(SUM(total_sales) / SUM(SUM(total_sales)) OVER () * 100, 2) AS pct_of_sales
FROM gold.report_products
GROUP BY product_segment
ORDER BY total_sales DESC;


-- Q61. Best product in every category (window function on the report view)
SELECT
    category,
    product_name,
    total_sales,
    product_rank
FROM
(
    SELECT
        category,
        product_name,
        total_sales,
        RANK() OVER (PARTITION BY category ORDER BY total_sales DESC) AS product_rank
    FROM gold.report_products
) AS ranked
WHERE product_rank = 1
ORDER BY total_sales DESC;


-- Q62. Products that have not sold in the last 6 months of the data
SELECT
    product_name,
    category,
    last_sale_date,
    recency_months,
    total_sales
FROM gold.report_products
WHERE recency_months >= 6
ORDER BY recency_months DESC, total_sales DESC;
