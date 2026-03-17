-- =============================================================
-- SECTION 0: SCHEMA SETUP
-- =============================================================

CREATE DATABASE IF NOT EXISTS olist_db;
USE olist_db;

-- Drop tables if re-running
DROP TABLE IF EXISTS olist_master;
DROP TABLE IF EXISTS olist_rfm;
DROP TABLE IF EXISTS olist_monthly;
DROP TABLE IF EXISTS olist_seller_kpi;

-- Main master table (load from ../data/cleaned/olist_master.csv)
CREATE TABLE olist_master (
    order_id                        VARCHAR(50),
    customer_id                     VARCHAR(50),
    order_status                    VARCHAR(20),
    order_purchase_timestamp        DATETIME,
    order_approved_at               DATETIME,
    order_delivered_carrier_date    DATETIME,
    order_delivered_customer_date   DATETIME,
    order_estimated_delivery_date   DATETIME,
    customer_unique_id              VARCHAR(50),
    customer_zip_code_prefix        INT,
    customer_city                   VARCHAR(100),
    customer_state                  VARCHAR(5),
    revenue                         DECIMAL(10,2),
    freight                         DECIMAL(10,2),
    items_count                     INT,
    payment_type                    VARCHAR(20),
    payment_installments            INT,
    payment_value                   DECIMAL(10,2),
    review_score                    DECIMAL(3,1),
    product_id                      VARCHAR(50),
    seller_id                       VARCHAR(50),
    product_category_name           VARCHAR(100),
    product_category_name_english   VARCHAR(100),
    seller_state                    VARCHAR(5),
    seller_city                     VARCHAR(100),
    delivery_delay_days             DECIMAL(8,1),
    delivery_time_days              DECIMAL(8,1),
    order_month                     VARCHAR(10),
    order_year                      INT,
    order_quarter                   VARCHAR(10),
    order_dow                       VARCHAR(15),
    order_hour                      INT
);

-- RFM table (load from ../data/cleaned/olist_rfm.csv)
CREATE TABLE olist_rfm (
    customer_unique_id  VARCHAR(50),
    recency             INT,
    frequency           INT,
    monetary            DECIMAL(10,2),
    R_score             INT,
    F_score             INT,
    M_score             INT,
    RFM_score           INT,
    segment             VARCHAR(30)
);

-- Seller KPI table (load from ../data/cleaned/olist_seller_kpi.csv)
CREATE TABLE olist_seller_kpi (
    seller_id           VARCHAR(50),
    total_revenue       DECIMAL(12,2),
    total_orders        INT,
    avg_review_score    DECIMAL(4,2),
    avg_delivery_delay  DECIMAL(6,2),
    seller_state        VARCHAR(5),
    seller_city         VARCHAR(100),
    revenue_rank        INT,
    performance_tier    VARCHAR(20)
);

-- Load CSVs (update path as needed — use forward slashes on Linux/Mac)
-- On Windows, use: LOAD DATA LOCAL INFILE 'C:/path/to/file.csv'
LOAD DATA LOCAL INFILE '../data/cleaned/olist_master.csv'
INTO TABLE olist_master
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '../data/cleaned/olist_rfm.csv'
INTO TABLE olist_rfm
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '../data/cleaned/olist_seller_kpi.csv'
INTO TABLE olist_seller_kpi
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- =============================================================
-- SECTION 1: BUSINESS OVERVIEW KPIs
-- =============================================================

-- 1.1 High-level business snapshot
SELECT
    COUNT(DISTINCT order_id)            AS total_orders,
    COUNT(DISTINCT customer_unique_id)  AS unique_customers,
    ROUND(SUM(revenue), 2)              AS total_revenue,
    ROUND(AVG(revenue), 2)              AS avg_order_value,
    ROUND(AVG(review_score), 2)         AS avg_review_score,
    ROUND(AVG(delivery_time_days), 1)   AS avg_delivery_days,
    SUM(CASE WHEN delivery_delay_days > 0 THEN 1 ELSE 0 END) AS late_deliveries,
    ROUND(SUM(CASE WHEN delivery_delay_days > 0 THEN 1 ELSE 0 END)
          / COUNT(*) * 100, 2)          AS late_pct
FROM olist_master;

-- 1.2 Revenue breakdown by year
SELECT
    order_year,
    COUNT(DISTINCT order_id)   AS total_orders,
    ROUND(SUM(revenue), 2)     AS total_revenue,
    ROUND(AVG(revenue), 2)     AS avg_order_value
FROM olist_master
GROUP BY order_year
ORDER BY order_year;

-- 1.3 Revenue and orders by quarter
SELECT
    order_quarter,
    COUNT(DISTINCT order_id)              AS total_orders,
    ROUND(SUM(revenue), 2)                AS total_revenue,
    ROUND(AVG(review_score), 2)           AS avg_review,
    ROUND(SUM(revenue) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM olist_master
GROUP BY order_quarter
ORDER BY order_quarter;


-- =============================================================
-- SECTION 2: REVENUE TREND ANALYSIS (WINDOW FUNCTIONS)
-- =============================================================

-- 2.1 Monthly revenue with MoM growth using LAG
WITH monthly_rev AS (
    SELECT
        order_month,
        ROUND(SUM(revenue), 2)        AS revenue,
        COUNT(DISTINCT order_id)      AS orders
    FROM olist_master
    WHERE order_month >= '2017-01'
    GROUP BY order_month
)
SELECT
    order_month,
    revenue,
    orders,
    LAG(revenue) OVER (ORDER BY order_month)    AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY order_month))
        / LAG(revenue) OVER (ORDER BY order_month) * 100, 2
    )                                            AS mom_growth_pct,
    ROUND(SUM(revenue) OVER (ORDER BY order_month
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS cumulative_revenue
FROM monthly_rev
ORDER BY order_month;

-- 2.2 3-month rolling average revenue
WITH monthly_rev AS (
    SELECT
        order_month,
        ROUND(SUM(revenue), 2) AS revenue
    FROM olist_master
    WHERE order_month >= '2017-01'
    GROUP BY order_month
)
SELECT
    order_month,
    revenue,
    ROUND(AVG(revenue) OVER (
        ORDER BY order_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3m_avg
FROM monthly_rev
ORDER BY order_month;

-- 2.3 Peak revenue day of week
SELECT
    order_dow,
    COUNT(order_id)            AS total_orders,
    ROUND(SUM(revenue), 2)     AS total_revenue,
    ROUND(AVG(revenue), 2)     AS avg_order_value
FROM olist_master
GROUP BY order_dow
ORDER BY total_orders DESC;


-- =============================================================
-- SECTION 3: PRODUCT CATEGORY ANALYSIS
-- =============================================================

-- 3.1 Top 15 categories by revenue
SELECT
    product_category_name_english,
    COUNT(DISTINCT order_id)                    AS orders,
    ROUND(SUM(revenue), 2)                      AS total_revenue,
    ROUND(AVG(revenue), 2)                      AS avg_order_value,
    ROUND(AVG(review_score), 2)                 AS avg_review,
    ROUND(SUM(revenue) / SUM(SUM(revenue))
          OVER () * 100, 2)                     AS revenue_share_pct
FROM olist_master
GROUP BY product_category_name_english
ORDER BY total_revenue DESC
LIMIT 15;

-- 3.2 Category revenue rank with running total (Pareto)
WITH cat_rev AS (
    SELECT
        product_category_name_english,
        ROUND(SUM(revenue), 2) AS revenue
    FROM olist_master
    GROUP BY product_category_name_english
)
SELECT
    product_category_name_english,
    revenue,
    RANK() OVER (ORDER BY revenue DESC)          AS revenue_rank,
    ROUND(revenue / SUM(revenue) OVER () * 100, 2) AS share_pct,
    ROUND(SUM(revenue) OVER (ORDER BY revenue DESC
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
          / SUM(revenue) OVER () * 100, 2)       AS cumulative_pct
FROM cat_rev
ORDER BY revenue DESC;

-- 3.3 Category performance: high revenue but low review score (problem categories)
SELECT
    product_category_name_english,
    ROUND(SUM(revenue), 2)       AS total_revenue,
    COUNT(DISTINCT order_id)     AS orders,
    ROUND(AVG(review_score), 2)  AS avg_review,
    ROUND(AVG(delivery_delay_days), 1) AS avg_delay_days
FROM olist_master
GROUP BY product_category_name_english
HAVING COUNT(DISTINCT order_id) >= 100
ORDER BY avg_review ASC
LIMIT 10;


-- =============================================================
-- SECTION 4: CUSTOMER ANALYSIS
-- =============================================================

-- 4.1 Customer retention — repeat vs one-time buyers
WITH customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM olist_master
    GROUP BY customer_unique_id
)
SELECT
    CASE WHEN order_count = 1 THEN 'One-time buyer'
         WHEN order_count = 2 THEN '2 orders'
         WHEN order_count <= 5 THEN '3-5 orders'
         ELSE '6+ orders'
    END                  AS buyer_type,
    COUNT(*)             AS customers,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS pct_of_customers
FROM customer_orders
GROUP BY buyer_type
ORDER BY customers DESC;

-- 4.2 Revenue by customer state with ranking
SELECT
    customer_state,
    COUNT(DISTINCT customer_unique_id)  AS customers,
    COUNT(DISTINCT order_id)            AS orders,
    ROUND(SUM(revenue), 2)              AS total_revenue,
    ROUND(AVG(revenue), 2)              AS avg_order_value,
    RANK() OVER (ORDER BY SUM(revenue) DESC) AS revenue_rank
FROM olist_master
GROUP BY customer_state
ORDER BY total_revenue DESC;

-- 4.3 State concentration — what % of revenue comes from top 3 states
WITH state_rev AS (
    SELECT
        customer_state,
        SUM(revenue) AS revenue
    FROM olist_master
    GROUP BY customer_state
),
total AS (
    SELECT SUM(revenue) AS grand_total FROM olist_master
)
SELECT
    s.customer_state,
    ROUND(s.revenue, 2)                            AS state_revenue,
    ROUND(s.revenue / t.grand_total * 100, 2)      AS share_pct
FROM state_rev s
CROSS JOIN total t
ORDER BY s.revenue DESC
LIMIT 5;

-- 4.4 RFM segment summary with revenue contribution
SELECT
    segment,
    COUNT(*)                          AS customers,
    ROUND(AVG(recency), 0)            AS avg_recency_days,
    ROUND(AVG(frequency), 1)          AS avg_orders,
    ROUND(AVG(monetary), 2)           AS avg_revenue,
    ROUND(SUM(monetary), 2)           AS total_revenue,
    ROUND(SUM(monetary) / SUM(SUM(monetary)) OVER () * 100, 2) AS revenue_share_pct
FROM olist_rfm
GROUP BY segment
ORDER BY avg_revenue DESC;

-- 4.5 High-value customer profile (top 10% by spend)
WITH ranked_customers AS (
    SELECT
        customer_unique_id,
        monetary,
        frequency,
        recency,
        segment,
        NTILE(10) OVER (ORDER BY monetary DESC) AS decile
    FROM olist_rfm
)
SELECT
    decile,
    COUNT(*)                   AS customers,
    ROUND(AVG(monetary), 2)    AS avg_spend,
    ROUND(SUM(monetary), 2)    AS total_spend,
    ROUND(AVG(frequency), 2)   AS avg_orders,
    ROUND(SUM(monetary) / SUM(SUM(monetary)) OVER () * 100, 2) AS revenue_share_pct
FROM ranked_customers
GROUP BY decile
ORDER BY decile;


-- =============================================================
-- SECTION 5: SELLER PERFORMANCE ANALYSIS
-- =============================================================

-- 5.1 Overall seller tier distribution
SELECT
    performance_tier,
    COUNT(*)                     AS sellers,
    ROUND(AVG(total_revenue), 2) AS avg_revenue,
    ROUND(SUM(total_revenue), 2) AS tier_revenue,
    ROUND(AVG(avg_review_score), 2) AS avg_review,
    ROUND(AVG(avg_delivery_delay), 1) AS avg_delay_days
FROM olist_seller_kpi
GROUP BY performance_tier
ORDER BY tier_revenue DESC;

-- 5.2 Top 20 sellers by revenue
SELECT
    seller_id,
    seller_state,
    seller_city,
    total_orders,
    ROUND(total_revenue, 2)      AS total_revenue,
    ROUND(avg_review_score, 2)   AS avg_review,
    ROUND(avg_delivery_delay, 1) AS avg_delay_days,
    performance_tier,
    revenue_rank
FROM olist_seller_kpi
ORDER BY revenue_rank
LIMIT 20;

-- 5.3 Sellers with high revenue but poor reviews (risk sellers)
SELECT
    seller_id,
    seller_state,
    total_orders,
    ROUND(total_revenue, 2)       AS total_revenue,
    ROUND(avg_review_score, 2)    AS avg_review,
    ROUND(avg_delivery_delay, 1)  AS avg_delay_days,
    performance_tier
FROM olist_seller_kpi
WHERE avg_review_score < 3.0
  AND total_orders >= 50
ORDER BY total_revenue DESC
LIMIT 15;

-- 5.4 Revenue by seller state
SELECT
    seller_state,
    COUNT(DISTINCT seller_id)    AS sellers,
    SUM(total_orders)            AS total_orders,
    ROUND(SUM(total_revenue), 2) AS total_revenue,
    ROUND(AVG(avg_review_score), 2) AS avg_review
FROM olist_seller_kpi
GROUP BY seller_state
ORDER BY total_revenue DESC
LIMIT 10;

-- 5.5 Seller performance quartile analysis (window function)
SELECT
    seller_id,
    total_revenue,
    total_orders,
    avg_review_score,
    NTILE(4) OVER (ORDER BY total_revenue)      AS revenue_quartile,
    NTILE(4) OVER (ORDER BY avg_review_score)   AS review_quartile,
    ROUND(total_revenue / SUM(total_revenue) OVER () * 100, 4) AS revenue_share_pct
FROM olist_seller_kpi
ORDER BY total_revenue DESC
LIMIT 30;


-- =============================================================
-- SECTION 6: DELIVERY & LOGISTICS ANALYSIS
-- =============================================================

-- 6.1 Delivery performance overview
SELECT
    CASE
        WHEN delivery_delay_days <= -10 THEN 'Very Early (10+ days)'
        WHEN delivery_delay_days < 0    THEN 'Early (1-9 days)'
        WHEN delivery_delay_days = 0    THEN 'Exactly On Time'
        WHEN delivery_delay_days <= 5   THEN 'Late (1-5 days)'
        WHEN delivery_delay_days <= 15  THEN 'Late (6-15 days)'
        ELSE 'Very Late (15+ days)'
    END                             AS delivery_bucket,
    COUNT(*)                        AS orders,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS pct,
    ROUND(AVG(review_score), 2)     AS avg_review_score
FROM olist_master
GROUP BY delivery_bucket
ORDER BY avg_review_score DESC;

-- 6.2 Monthly late delivery rate trend
SELECT
    order_month,
    COUNT(*)                                              AS total_orders,
    SUM(CASE WHEN delivery_delay_days > 0 THEN 1 ELSE 0 END) AS late_orders,
    ROUND(SUM(CASE WHEN delivery_delay_days > 0 THEN 1 ELSE 0 END)
          / COUNT(*) * 100, 2)                            AS late_rate_pct,
    ROUND(AVG(review_score), 2)                          AS avg_review
FROM olist_master
WHERE order_month >= '2017-01'
GROUP BY order_month
ORDER BY order_month;

-- 6.3 Average delivery time by state (logistics efficiency)
SELECT
    customer_state,
    COUNT(*) AS orders,
    ROUND(AVG(delivery_time_days), 1)   AS avg_delivery_days,
    ROUND(AVG(delivery_delay_days), 1)  AS avg_delay_days,
    ROUND(AVG(review_score), 2)         AS avg_review
FROM olist_master
GROUP BY customer_state
HAVING COUNT(*) >= 100
ORDER BY avg_delivery_days DESC
LIMIT 15;

-- 6.4 Financial impact of late deliveries
SELECT
    CASE WHEN delivery_delay_days > 0 THEN 'Late' ELSE 'On Time / Early' END AS status,
    COUNT(*)                        AS orders,
    ROUND(AVG(revenue), 2)          AS avg_revenue,
    ROUND(SUM(revenue), 2)          AS total_revenue,
    ROUND(AVG(review_score), 2)     AS avg_review_score
FROM olist_master
GROUP BY status;


-- =============================================================
-- SECTION 7: PAYMENT BEHAVIOUR ANALYSIS
-- =============================================================

-- 7.1 Payment method summary
SELECT
    payment_type,
    COUNT(DISTINCT order_id)                AS orders,
    ROUND(SUM(payment_value), 2)            AS total_payment_value,
    ROUND(AVG(payment_value), 2)            AS avg_order_value,
    ROUND(AVG(payment_installments), 1)     AS avg_installments,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS order_share_pct
FROM olist_master
WHERE payment_type != 'not_defined'
GROUP BY payment_type
ORDER BY orders DESC;

-- 7.2 Installment behaviour — credit card orders
SELECT
    payment_installments,
    COUNT(*)                   AS orders,
    ROUND(AVG(revenue), 2)     AS avg_order_value,
    ROUND(SUM(revenue), 2)     AS total_revenue
FROM olist_master
WHERE payment_type = 'credit_card'
GROUP BY payment_installments
ORDER BY payment_installments;

-- 7.3 Payment type preference by top 5 states
SELECT
    customer_state,
    payment_type,
    COUNT(*) AS orders,
    RANK() OVER (PARTITION BY customer_state ORDER BY COUNT(*) DESC) AS rank_within_state
FROM olist_master
WHERE customer_state IN ('SP','RJ','MG','RS','PR')
  AND payment_type != 'not_defined'
GROUP BY customer_state, payment_type
ORDER BY customer_state, rank_within_state;


-- =============================================================
-- SECTION 8: BUSINESS INSIGHT SUMMARY QUERIES
-- =============================================================

-- 8.1 Insight 1: Revenue concentration (80/20 rule check)
WITH customer_rev AS (
    SELECT
        customer_unique_id,
        SUM(revenue) AS customer_revenue,
        NTILE(10) OVER (ORDER BY SUM(revenue) DESC) AS decile
    FROM olist_master
    GROUP BY customer_unique_id
)
SELECT
    decile,
    COUNT(*)                    AS customers,
    ROUND(SUM(customer_revenue), 2) AS revenue,
    ROUND(SUM(customer_revenue) / SUM(SUM(customer_revenue)) OVER () * 100, 2) AS revenue_pct
FROM customer_rev
GROUP BY decile
ORDER BY decile;

-- 8.2 Insight 2: Best month + category combination
SELECT
    order_month,
    product_category_name_english,
    ROUND(SUM(revenue), 2)  AS revenue,
    COUNT(order_id)         AS orders,
    RANK() OVER (PARTITION BY order_month ORDER BY SUM(revenue) DESC) AS rank_in_month
FROM olist_master
WHERE order_month >= '2017-01'
GROUP BY order_month, product_category_name_english
HAVING rank_in_month = 1
ORDER BY order_month;

-- 8.3 Insight 3: Champion customers — who are they?
SELECT
    r.customer_unique_id,
    r.recency,
    r.frequency,
    ROUND(r.monetary, 2)         AS total_spend,
    r.RFM_score,
    m.customer_state,
    m.customer_city,
    m.payment_type
FROM olist_rfm r
JOIN olist_master m ON r.customer_unique_id = m.customer_unique_id
WHERE r.segment = 'Champions'
GROUP BY r.customer_unique_id, r.recency, r.frequency, r.monetary,
         r.RFM_score, m.customer_state, m.customer_city, m.payment_type
ORDER BY r.monetary DESC
LIMIT 20;

-- 8.4 Insight 4: Churn risk — high-spend customers going silent
SELECT
    r.customer_unique_id,
    ROUND(r.monetary, 2)    AS total_spend,
    r.recency               AS days_since_last_order,
    r.frequency             AS total_orders,
    r.segment
FROM olist_rfm r
WHERE r.segment = 'At Risk'
  AND r.monetary > 500
ORDER BY r.monetary DESC
LIMIT 20;

-- =============================================================
-- END OF SQL ANALYSIS
-- =============================================================
