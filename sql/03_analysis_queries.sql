-- Urban Threads: business analysis queries
-- Run after importing the CSV and creating vw_clean_orders.
-- All comments explain the business question each query answers.

-- Q1. Overall KPIs for all rows in the supplied CSV.
-- This reproduces the report's all-file scope; note that one order date is outside Q4.
SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total), 2) AS recorded_revenue,
    ROUND(SUM(total) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS average_order_value,
    COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'Delivered') AS delivered_orders,
    COUNT(DISTINCT order_id) FILTER (WHERE is_returned = TRUE) AS returned_orders,
    ROUND(
        100.0 * COUNT(DISTINCT order_id) FILTER (WHERE is_returned = TRUE)
        / NULLIF(COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'Delivered'), 0), 2
    ) AS return_rate_pct
FROM urban_threads.vw_clean_orders;

-- Q2. KPIs for Q4 2024 only. Compare this with Q1 because the raw file has one out-of-quarter date.
SELECT
    COUNT(DISTINCT order_id) AS q4_orders,
    ROUND(SUM(total), 2) AS q4_recorded_revenue,
    ROUND(SUM(total) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS q4_average_order_value,
    COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'Delivered') AS q4_delivered_orders,
    COUNT(DISTINCT order_id) FILTER (WHERE is_returned = TRUE) AS q4_returned_orders,
    ROUND(
        100.0 * COUNT(DISTINCT order_id) FILTER (WHERE is_returned = TRUE)
        / NULLIF(COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'Delivered'), 0), 2
    ) AS q4_return_rate_pct
FROM urban_threads.vw_clean_orders
WHERE order_date >= DATE '2024-10-01'
  AND order_date < DATE '2025-01-01';

-- Q3. Return rate by customer type (returned orders / delivered orders in each segment).
SELECT
    customer_type,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'Delivered') AS delivered_orders,
    COUNT(DISTINCT order_id) FILTER (WHERE is_returned = TRUE) AS returned_orders,
    ROUND(
        100.0 * COUNT(DISTINCT order_id) FILTER (WHERE is_returned = TRUE)
        / NULLIF(COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'Delivered'), 0), 2
    ) AS return_rate_pct
FROM urban_threads.vw_clean_orders
WHERE order_date >= DATE '2024-10-01'
  AND order_date < DATE '2025-01-01'
GROUP BY customer_type
ORDER BY return_rate_pct DESC NULLS LAST;

-- Q4. Return rate by order source.
SELECT
    order_source,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'Delivered') AS delivered_orders,
    COUNT(DISTINCT order_id) FILTER (WHERE is_returned = TRUE) AS returned_orders,
    ROUND(
        100.0 * COUNT(DISTINCT order_id) FILTER (WHERE is_returned = TRUE)
        / NULLIF(COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'Delivered'), 0), 2
    ) AS return_rate_pct
FROM urban_threads.vw_clean_orders
WHERE order_date >= DATE '2024-10-01'
  AND order_date < DATE '2025-01-01'
GROUP BY order_source
ORDER BY return_rate_pct DESC NULLS LAST;

-- Q5. Return rate by payment method.
SELECT
    payment_method,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'Delivered') AS delivered_orders,
    COUNT(DISTINCT order_id) FILTER (WHERE is_returned = TRUE) AS returned_orders,
    ROUND(
        100.0 * COUNT(DISTINCT order_id) FILTER (WHERE is_returned = TRUE)
        / NULLIF(COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'Delivered'), 0), 2
    ) AS return_rate_pct
FROM urban_threads.vw_clean_orders
WHERE order_date >= DATE '2024-10-01'
  AND order_date < DATE '2025-01-01'
GROUP BY payment_method
ORDER BY return_rate_pct DESC NULLS LAST;

-- Q6. Return rate by product category.
SELECT
    category,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'Delivered') AS delivered_orders,
    COUNT(DISTINCT order_id) FILTER (WHERE is_returned = TRUE) AS returned_orders,
    ROUND(
        100.0 * COUNT(DISTINCT order_id) FILTER (WHERE is_returned = TRUE)
        / NULLIF(COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'Delivered'), 0), 2
    ) AS return_rate_pct
FROM urban_threads.vw_clean_orders
WHERE order_date >= DATE '2024-10-01'
  AND order_date < DATE '2025-01-01'
GROUP BY category
ORDER BY return_rate_pct DESC NULLS LAST;

-- Q7. Weekly order volume during Q4 2024.
SELECT
    DATE_TRUNC('week', order_date)::date AS week_start,
    COUNT(DISTINCT order_id) AS order_count,
    ROUND(SUM(total), 2) AS recorded_revenue
FROM urban_threads.vw_clean_orders
WHERE order_date >= DATE '2024-10-01'
  AND order_date < DATE '2025-01-01'
GROUP BY DATE_TRUNC('week', order_date)::date
ORDER BY week_start;

-- Q8. Return reasons: identify the most common reported reasons.
SELECT
    COALESCE(return_reason, 'Not specified') AS return_reason,
    COUNT(DISTINCT order_id) AS returned_orders
FROM urban_threads.vw_clean_orders
WHERE is_returned = TRUE
  AND order_date >= DATE '2024-10-01'
  AND order_date < DATE '2025-01-01'
GROUP BY COALESCE(return_reason, 'Not specified')
ORDER BY returned_orders DESC;

-- Q9. Return/refund status overview.
SELECT
    refund_status,
    COUNT(DISTINCT order_id) AS order_count
FROM urban_threads.vw_clean_orders
WHERE is_returned = TRUE
  AND order_date >= DATE '2024-10-01'
  AND order_date < DATE '2025-01-01'
GROUP BY refund_status
ORDER BY order_count DESC;

-- Q10. High-return segments with minimum delivered order volume of 10.
-- Use this to avoid overreacting to tiny segments; the threshold is an analysis choice.
WITH segment_summary AS (
    SELECT
        order_source,
        payment_method,
        COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'Delivered') AS delivered_orders,
        COUNT(DISTINCT order_id) FILTER (WHERE is_returned = TRUE) AS returned_orders
    FROM urban_threads.vw_clean_orders
    WHERE order_date >= DATE '2024-10-01'
      AND order_date < DATE '2025-01-01'
    GROUP BY order_source, payment_method
)
SELECT
    order_source,
    payment_method,
    delivered_orders,
    returned_orders,
    ROUND(100.0 * returned_orders / NULLIF(delivered_orders, 0), 2) AS return_rate_pct
FROM segment_summary
WHERE delivered_orders >= 10
ORDER BY return_rate_pct DESC NULLS LAST;
