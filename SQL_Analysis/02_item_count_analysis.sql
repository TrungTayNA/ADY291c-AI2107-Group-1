-- 02_item_count_analysis.sql
-- Relationship between the number of items in an order and the low review rate.

SELECT
    item_count,
    COUNT(*) AS total_orders,
    SUM(low_review) AS low_review_orders,
    ROUND(100.0 * SUM(low_review) / COUNT(*), 2) AS low_review_rate
FROM olist_model_dataset
GROUP BY item_count
ORDER BY item_count;
