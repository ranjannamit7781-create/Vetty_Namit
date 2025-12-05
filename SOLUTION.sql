-- SQL Test Solutions (based on dataset in provided PDF)
-- Assumptions:
-- 1) Table names: transactions, items
-- 2) Timestamps stored as proper TIMESTAMP or TIMESTAMP WITH TIME ZONE
-- 3) Columns in `transactions`: buyer_id, purchase_time, refund_time, refund_item, store_id, item_id, gross_transaction_value
-- 4) Columns in `items`: store_id, item_id, item_category, item_name
-- 5) SQL dialect used: Postgres-compatible (uses DATE_TRUNC, EXTRACT(EPOCH), window functions)

--------------------------------------------------------------------------------
-- 1) Count of purchases per month (excluding refunded purchases)
--------------------------------------------------------------------------------
/*
 Explanation:
 - Exclude rows where refund_time IS NOT NULL (these are refunded purchases).
 - Group by month (using DATE_TRUNC) and count purchases.
*/
SELECT
    DATE_TRUNC('month', purchase_time) AS month,
    COUNT(*) AS purchase_count
FROM transactions
WHERE refund_time IS NULL
GROUP BY 1
ORDER BY 1;

--------------------------------------------------------------------------------
-- 2) How many stores receive at least 5 orders/transactions in October 2020?
--------------------------------------------------------------------------------
/*
 Explanation:
 - Filter purchases to October 2020 (>= '2020-10-01' AND < '2020-11-01')
 - Group by store_id, count transactions, then count stores with tx_count >= 5
*/
WITH oct_tx AS (
    SELECT store_id, COUNT(*) AS tx_count
    FROM transactions
    WHERE purchase_time >= '2020-10-01'::timestamp
      AND purchase_time <  '2020-11-01'::timestamp
    GROUP BY store_id
)
SELECT COUNT(*) AS stores_with_5_plus_orders
FROM oct_tx
WHERE tx_count >= 5;

--------------------------------------------------------------------------------
-- 3) For each store, shortest interval (minutes) from purchase to refund time
--------------------------------------------------------------------------------
/*
 Explanation:
 - Consider only refunded transactions (refund_time IS NOT NULL).
 - Compute refund_time - purchase_time, convert to minutes (EXTRACT(EPOCH) / 60)
 - Use MIN(...) per store to get the shortest interval
*/
SELECT
    store_id,
    MIN(EXTRACT(EPOCH FROM (refund_time - purchase_time)) / 60.0) AS min_refund_interval_minutes
FROM transactions
WHERE refund_time IS NOT NULL
GROUP BY store_id
ORDER BY store_id;

--------------------------------------------------------------------------------
-- 4) gross_transaction_value of every store's first order
--------------------------------------------------------------------------------
/*
 Explanation:
 - Partition by store_id and order by purchase_time ascending.
 - Use ROW_NUMBER to pick the first row per store.
*/
WITH ordered AS (
    SELECT
        store_id,
        gross_transaction_value,
        purchase_time,
        ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY purchase_time) AS rn
    FROM transactions
)
SELECT store_id, gross_transaction_value, purchase_time
FROM ordered
WHERE rn = 1
ORDER BY store_id;

--------------------------------------------------------------------------------
-- 5) Most popular item_name that buyers order on their first purchase
--------------------------------------------------------------------------------
/*
 Explanation:
 - For each buyer, determine their first purchase (ROW_NUMBER over buyer_id ordered by purchase_time)
 - Join to items to get item_name
 - Count frequencies and return top 1
*/
WITH first_purchase AS (
    SELECT
        t.*,
        ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
    FROM transactions t
)
SELECT i.item_name, COUNT(*) AS cnt
FROM first_purchase fp
JOIN items i ON fp.item_id = i.item_id
WHERE fp.rn = 1
GROUP BY i.item_name
ORDER BY cnt DESC
LIMIT 1;

--------------------------------------------------------------------------------
-- 6) Create a flag in transactions indicating whether refund can be processed (within 72 hours)
--------------------------------------------------------------------------------
/*
 Explanation:
 - Refund processable if refund_time IS NOT NULL and refund_time - purchase_time <= 72 hours.
 - Use EXTRACT(EPOCH)/3600 to convert seconds to hours.
*/
SELECT
    *,
    CASE
        WHEN refund_time IS NULL THEN 'NO_REFUND'
        WHEN (EXTRACT(EPOCH FROM (refund_time - purchase_time)) / 3600.0) <= 72 THEN 'PROCESS'
        ELSE 'DO_NOT_PROCESS'
    END AS refund_flag
FROM transactions;

--------------------------------------------------------------------------------
-- 7) Create a rank by buyer_id and filter for only the second purchase per buyer (ignore refunds)
--------------------------------------------------------------------------------
/*
 Explanation:
 - Use ROW_NUMBER() partitioned by buyer_id ordered by purchase_time.
 - rn = 2 is the second purchase.
 - The instruction "Ignore refunds here" means do not exclude rows based on refund_time.
*/
WITH ranked AS (
    SELECT
        t.*,
        ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
    FROM transactions t
)
SELECT *
FROM ranked
WHERE rn = 2;

--------------------------------------------------------------------------------
-- 8) How to find the second transaction time per buyer (don't use min/max)
--------------------------------------------------------------------------------
/*
 Explanation:
 - Same window function approach returning buyer_id and their second purchase_time.
*/
SELECT buyer_id, purchase_time AS second_purchase_time
FROM (
    SELECT
        buyer_id,
        purchase_time,
        ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
    FROM transactions
) sub
WHERE rn = 2;
