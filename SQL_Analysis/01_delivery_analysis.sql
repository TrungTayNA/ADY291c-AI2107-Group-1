-- 01_delivery_analysis.sql
-- Compare late orders with on-time/early orders and their low review rate.

-- Overall counts: late orders, on-time/early orders and low review orders
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN delay_days > 0 THEN 1 ELSE 0 END) AS late_orders,
    SUM(CASE WHEN delay_days <= 0 THEN 1 ELSE 0 END) AS on_time_orders,
    SUM(low_review) AS low_review_orders
FROM olist_analysis_dataset;

-- Low review rate for each delivery group (Late vs On time / Early)
SELECT
    CASE
        WHEN delay_days > 0 THEN 'Late'
        ELSE 'On time / Early'
    END AS delivery_status,
    COUNT(*) AS total_orders,
    SUM(low_review) AS low_review_orders,
    ROUND(100.0 * SUM(low_review) / COUNT(*), 2) AS low_review_rate
FROM olist_analysis_dataset
GROUP BY delivery_status
ORDER BY delivery_status;
