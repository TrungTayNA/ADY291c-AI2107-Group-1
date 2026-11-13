-- 03_delay_group_analysis.sql
-- Low review rate by delay group (early/on time, 1-3, 4-7, over 7 days late).

SELECT
    CASE
        WHEN delay_days <= 0 THEN 'Early / On time'
        WHEN delay_days BETWEEN 1 AND 3 THEN '1-3 days late'
        WHEN delay_days BETWEEN 4 AND 7 THEN '4-7 days late'
        ELSE 'Over 7 days late'
    END AS delay_group,
    COUNT(*) AS total_orders,
    SUM(low_review) AS low_review_orders,
    ROUND(100.0 * SUM(low_review) / COUNT(*), 2) AS low_review_rate
FROM olist_model_dataset
GROUP BY delay_group
ORDER BY MIN(delay_days);
