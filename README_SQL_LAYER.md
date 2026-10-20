# Urban Threads — SQL Analysis Layer (PostgreSQL)

This folder adds a PostgreSQL/SQL analysis stage to the existing Excel + Power BI project. It is an extension of the cloned project, not part of the original documented workflow.

## Files

- `01_create_table.sql` — creates the schema and raw table.
- `02_cleaning_and_validation.sql` — creates a cleaned view and data-quality checks.
- `03_analysis_queries.sql` — ten business analysis queries.

## Workflow

`Raw_data.csv → PostgreSQL raw table → cleaned SQL view → SQL analysis → Power BI`

## Setup in pgAdmin (Windows)

1. Open pgAdmin and connect to your PostgreSQL server.
2. Create a database named `urban_threads` (or use another database and connect to it).
3. Open **Tools → Query Tool** for that database.
4. Open and run `01_create_table.sql`.
5. In the browser tree, find `Schemas → urban_threads → Tables → raw_orders`.
6. Right-click `raw_orders` → **Import/Export Data**.
7. Choose **Import**, select the supplied `Raw_data.csv`, choose CSV format, enable **Header**, and import the file. Make sure empty fields are treated as NULL. The CSV's column order must remain unchanged.
8. Run `02_cleaning_and_validation.sql` to create the view and inspect quality checks.
9. Run `03_analysis_queries.sql`, one query at a time or as a whole, and review each result grid.

If pgAdmin's import dialog has a setting for NULL strings, use an empty value for blank CSV fields. If a date or numeric import fails, inspect the CSV and import settings rather than silently dropping rows.

## Important data-quality notes

The supplied CSV contains 346 records, but one record (`UT-100003`) has `Order Date = 2024-01-10`, outside Q4 2024. Therefore:

- The full-file KPIs include all 346 records, matching the scope used by the original summary.
- The Q4-only queries filter dates from 2024-10-01 inclusive to 2025-01-01 exclusive and will exclude that row.
- The cleaning view flags the date instead of silently changing it.
- The view standardizes `new` to `New`, corrects `Delievered` to `Delivered`, and exposes a separate `qty_cleaned` value where `-1` is treated as `1` based on the original cleaning log. The raw source values remain unchanged.

The original report's overall return rate is approximately 55% (180 orders marked returned / 328 delivered orders). Validate the business definition before comparing segment-level percentages: this SQL uses returned orders divided by delivered orders within each segment. The revenue field is named `recorded_revenue` in the queries because the dataset does not establish that it is net of refunds, returns, or operating costs; it should not be called profit.

## Connecting Power BI (optional)

In Power BI Desktop, choose **Get Data → PostgreSQL database**, enter the server and database, then select `urban_threads.vw_clean_orders` (or load the analysis results as appropriate). Use the same denominator definition in Power BI measures so the SQL and dashboard numbers agree. Do not overwrite the original dashboard until the results have been reconciled.

## Interview talking points

- SQL is used to validate the source, standardize values in a view, calculate KPIs, and compare return rates by customer type, order source, payment method, and product category.
- `COUNT(DISTINCT order_id)` avoids counting an order more than once if the data later gains duplicate rows.
- `FILTER (WHERE ...)` calculates conditional counts in PostgreSQL.
- `NULLIF(denominator, 0)` prevents division-by-zero errors.
- The raw table is preserved; transformations are visible in a view, which makes the cleaning logic auditable.
- This is a new SQL extension. Only describe it as implemented after running the scripts and checking the results yourself.
