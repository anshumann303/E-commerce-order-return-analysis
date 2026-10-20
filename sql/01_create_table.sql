-- Urban Threads: Q4 2024 Order & Return Analysis
-- Step 1: Run this file in pgAdmin Query Tool to create the schema and raw table.
-- Then import Raw_data.csv into urban_threads.raw_orders using pgAdmin's Import/Export tool.
-- IMPORTANT: preserve the CSV column order shown below.

CREATE SCHEMA IF NOT EXISTS urban_threads;

DROP VIEW IF EXISTS urban_threads.vw_clean_orders CASCADE;
DROP TABLE IF EXISTS urban_threads.raw_orders CASCADE;

CREATE TABLE urban_threads.raw_orders (
    order_id        TEXT,
    order_date      DATE,
    customer_id     TEXT,
    customer_type   TEXT,
    sku             TEXT,
    category        TEXT,
    product_name    TEXT,
    unit_price      NUMERIC(12,2),
    qty             INTEGER,
    total           NUMERIC(12,2),
    discount_code   TEXT,
    discount_pct    NUMERIC(5,2),
    payment_method  TEXT,
    order_source    TEXT,
    city            TEXT,
    state           TEXT,
    warehouse       TEXT,
    delivery_date   DATE,
    order_status    TEXT,
    return_flag     TEXT,
    return_reason   TEXT,
    return_received_date DATE,
    refund_status   TEXT
);

-- After running this file, import the CSV:
-- pgAdmin > select urban_threads.raw_orders > Import/Export Data
-- Import = Yes; Filename = path to Raw_data.csv; Format = CSV; Header = Yes.
-- Ensure the empty CSV fields are imported as NULL values.
