-- 04_combined_analysis.sql
-- Low review rate by delivery status (Late / On time - Early) and item group.

SELECT
    CASE
        WHEN delay_days > 0 THEN 'Late'
        ELSE 'On time / Early'
    END AS delivery_status,
    CASE
        WHEN item_count = 1 THEN '1 item'
        WHEN item_count BETWEEN 2 AND 3 THEN '2-3 items'
        ELSE '4+ items'
    END AS item_group,
    COUNT(*) AS total_orders,
    SUM(low_review) AS low_review_orders,
    ROUND(100.0 * SUM(low_review) / COUNT(*), 2) AS low_review_rate
FROM olist_analysis_dataset
GROUP BY delivery_status, item_group
ORDER BY delivery_status, item_group;
