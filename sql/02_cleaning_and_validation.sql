-- Urban Threads: standardization layer and data-quality checks
-- This view keeps the raw table unchanged and applies transparent, reversible rules.

CREATE OR REPLACE VIEW urban_threads.vw_clean_orders AS
SELECT
    order_id,
    order_date,
    customer_id,
    CASE
        WHEN LOWER(TRIM(customer_type)) = 'new' THEN 'New'
        WHEN LOWER(TRIM(customer_type)) = 'returning' THEN 'Returning'
        ELSE TRIM(customer_type)
    END AS customer_type,
    sku,
    TRIM(category) AS category,
    product_name,
    unit_price,
    qty AS original_qty,
    CASE WHEN qty = -1 THEN 1 ELSE qty END AS qty_cleaned,
    total,
    NULLIF(TRIM(discount_code), '') AS discount_code,
    discount_pct,
    TRIM(payment_method) AS payment_method,
    TRIM(order_source) AS order_source,
    TRIM(city) AS city,
    TRIM(state) AS state,
    TRIM(warehouse) AS warehouse,
    delivery_date,
    CASE
        WHEN LOWER(TRIM(order_status)) = 'delievered' THEN 'Delivered'
        ELSE TRIM(order_status)
    END AS order_status,
    CASE
        WHEN LOWER(TRIM(return_flag)) = 'yes' THEN TRUE
        WHEN LOWER(TRIM(return_flag)) = 'no' THEN FALSE
        ELSE NULL
    END AS is_returned,
    NULLIF(TRIM(return_reason), '') AS return_reason,
    return_received_date,
    TRIM(refund_status) AS refund_status,
    CASE
        WHEN order_date < DATE '2024-10-01' OR order_date >= DATE '2025-01-01'
            THEN TRUE
        ELSE FALSE
    END AS outside_q4_2024,
    CASE WHEN qty = -1 THEN TRUE ELSE FALSE END AS quantity_was_corrected
FROM urban_threads.raw_orders;

-- 1. Check imported row count (expected: 346 for the supplied file).
SELECT COUNT(*) AS imported_rows FROM urban_threads.raw_orders;

-- 2. Check duplicate order IDs (expected: 0 in the supplied file).
SELECT order_id, COUNT(*) AS row_count
FROM urban_threads.raw_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 3. Inspect dates outside Q4 2024. Do not silently change these dates.
SELECT order_id, order_date, order_status
FROM urban_threads.vw_clean_orders
WHERE outside_q4_2024 = TRUE;

-- 4. Review values that were standardized in the view.
SELECT order_id, customer_type, original_qty, qty_cleaned, order_status,
       quantity_was_corrected, outside_q4_2024
FROM urban_threads.vw_clean_orders
WHERE quantity_was_corrected = TRUE
   OR outside_q4_2024 = TRUE
   OR order_id IN (
       SELECT order_id FROM urban_threads.raw_orders
       WHERE TRIM(customer_type) <> INITCAP(LOWER(TRIM(customer_type)))
          OR LOWER(TRIM(order_status)) = 'delievered'
   );

-- 5. Check invalid quantities and discount ranges in the raw data.
SELECT order_id, qty, discount_pct
FROM urban_threads.raw_orders
WHERE qty <= 0 OR discount_pct < 0 OR discount_pct > 100;

-- 6. Review return/refund combinations for business-rule validation.
SELECT order_id, order_status, return_flag, return_reason, refund_status
FROM urban_threads.vw_clean_orders
WHERE (is_returned = TRUE AND return_reason IS NULL)
   OR (is_returned = FALSE AND return_reason IS NOT NULL)
   OR (is_returned = FALSE AND refund_status NOT ILIKE 'Not Applicable');
