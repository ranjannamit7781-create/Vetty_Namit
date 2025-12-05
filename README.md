# Vetty_Namit
Description for Vettys SQL TEST.
SQL Test — Solutions & Explanations
==================================

Files included:
- sql_solutions.sql      : SQL file containing queries for questions 1 through 8
- README.md              : This file (explanation and assumptions)

Assumptions:
1) The dataset has two tables named exactly: `transactions` and `items`.
2) `transactions` contains the following columns (at minimum): 
   buyer_id, purchase_time, refund_time, refund_item, store_id, item_id, gross_transaction_value
3) `items` contains at least: store_id, item_id, item_category, item_name
4) Timestamps are stored in a SQL TIMESTAMP-compatible column (Postgres). If using another dialect, minor syntax tweaks may be required.
5) For question 1 we treat refunded purchases as those rows where refund_time IS NOT NULL.

Notes on outputs:
- Q1: Returns month buckets and counts excluding refunded purchases.
- Q2: Returns a single number indicating how many stores had >= 5 purchases in Oct 2020.
- Q3: Returns the shortest refund interval in minutes per store (only refunded rows considered).
- Q4: Returns each store's first order with gross_transaction_value.
- Q5: Returns the most popular item_name among buyers' first purchases.
- Q6: Adds a refund_flag showing whether a refund can be processed (<=72 hours).
- Q7: Returns rows that are the second purchase per buyer (rn = 2).
- Q8: Returns buyer_id and the timestamp of their second transaction.

How to run:
1) Load your dataset into a Postgres (or compatible) database with table names as assumed.
2) Run `psql` or your SQL client and execute `\i sql_solutions.sql`.
3) For screenshot evidence (recommended in the test) run each block query individually and take a screenshot.

If you want:
- I can adapt the queries to MySQL, SQL Server, or BigQuery dialects.
- I can generate sample CSV -> load scripts and mock output screenshots using the small dataset from the PDF.
