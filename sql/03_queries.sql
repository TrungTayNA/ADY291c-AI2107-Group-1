-- ============================================================
-- SQL ANALYSIS QUERIES
-- Target DBMS : SQLite 3.x
-- Dataset     : Olist Brazilian E-Commerce (2016-2018)
-- Questions   : Q1-Q8
-- ============================================================

PRAGMA foreign_keys = ON;


-- ============================================================
-- VIEW 1: BASE VIEW - MOT DONG MOI DON HANG DA GIAO
-- Tong hop item va thanh toan truoc khi JOIN de tranh nhan doi.
-- ============================================================
DROP VIEW IF EXISTS v_review_order_features;
CREATE VIEW v_review_order_features AS
WITH ranked_reviews AS (
    SELECT
        review_id,
        order_id,
        review_score,
        review_creation_date,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY datetime(review_creation_date) DESC, review_id DESC
        ) AS review_rank
    FROM order_reviews
),
items_by_order AS (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        COUNT(DISTINCT seller_id) AS seller_count,
        SUM(price) AS total_item_price,
        SUM(freight_value) AS total_freight
    FROM order_items
    GROUP BY order_id
),
payments_by_order AS (
    SELECT
        order_id,
        MAX(payment_installments) AS max_installments,
        MAX(CASE WHEN payment_sequential = 1 THEN payment_type END) AS first_payment_type
    FROM order_payments
    GROUP BY order_id
)
SELECT
    o.order_id,
    c.customer_state,
    o.purchase_year_month,
    o.delivery_days,
    o.estimated_days,
    o.delay_days,
    o.is_late,
    i.item_count,
    i.seller_count,
    i.total_item_price,
    i.total_freight,
    CASE
        WHEN i.total_item_price > 0
        THEN ROUND(100.0 * i.total_freight / i.total_item_price, 2)
        ELSE NULL
    END AS freight_to_price_pct,
    p.max_installments,
    p.first_payment_type,
    r.review_score
FROM orders o
JOIN ranked_reviews r
  ON r.order_id = o.order_id AND r.review_rank = 1
JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN items_by_order i ON i.order_id = o.order_id
LEFT JOIN payments_by_order p ON p.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND i.item_count IS NOT NULL;


-- ============================================================
-- Q1: PHAN BO REVIEW SCORE VA MAT CAN BANG LOP
-- ============================================================
SELECT
    review_score,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM v_review_order_features), 2) AS percentage,
    ROUND(100.0 * SUM(CASE WHEN review_score >= 4 THEN 1 ELSE 0 END)
          / COUNT(*), 2) AS positive_pct
FROM v_review_order_features
GROUP BY review_score
ORDER BY review_score;

SELECT
    CASE
        WHEN review_score <= 2 THEN 'Kem (1-2)'
        WHEN review_score = 3 THEN 'Trung binh (3)'
        ELSE 'Tot (4-5)'
    END AS score_group,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM v_review_order_features), 2) AS percentage
FROM v_review_order_features
GROUP BY score_group
ORDER BY MIN(review_score);


-- ============================================================
-- Q2: DON GIAO TRE CO REVIEW THAP HON DON DUNG HAN?
-- ============================================================
SELECT
    CASE WHEN is_late = 1 THEN 'Giao tre'
         ELSE 'Dung han hoac som' END AS delivery_group,
    COUNT(*) AS order_count,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    ROUND(100.0 * AVG(CASE WHEN review_score >= 4 THEN 1 ELSE 0 END), 2) AS positive_pct,
    ROUND(100.0 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 2) AS low_score_pct
FROM v_review_order_features
GROUP BY is_late
ORDER BY delivery_group;


-- ============================================================
-- Q3: MUC DO TRE 0; 1-3; 4-7; >7 NGAY
-- ============================================================
SELECT
    CASE
        WHEN delay_days <= 0 THEN 'Som hoac dung han'
        WHEN delay_days <= 3 THEN 'Tre 1-3 ngay'
        WHEN delay_days <= 7 THEN 'Tre 4-7 ngay'
        ELSE 'Tre tren 7 ngay'
    END AS delay_group,
    COUNT(*) AS order_count,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    ROUND(100.0 * AVG(CASE WHEN review_score >= 4 THEN 1 ELSE 0 END), 2) AS positive_pct
FROM v_review_order_features
WHERE delay_days IS NOT NULL
GROUP BY delay_group
ORDER BY MIN(CASE
    WHEN delay_days <= 0 THEN 0
    WHEN delay_days <= 3 THEN 1
    WHEN delay_days <= 7 THEN 2
    ELSE 3 END);


-- ============================================================
-- Q4: PHI VAN CHUYEN VA TY LE PHI/ GIA HANG CO ANH HUONG REVIEW?
-- ============================================================
WITH ship_fee_data AS (
    -- Chi giu hai cot can thiet: phi ship va review.
    SELECT total_freight AS metric_value, review_score
    FROM v_review_order_features
),
ship_fee_quartiles AS (
    -- NTILE(4): chia don theo phi ship tang dan thanh 4 nhom gan bang nhau.
    SELECT metric_value, review_score,
           NTILE(4) OVER (ORDER BY metric_value) AS quartile_number
    FROM ship_fee_data
),
ship_fee_ratio_data AS (
    SELECT freight_to_price_pct AS metric_value, review_score
    FROM v_review_order_features
    WHERE freight_to_price_pct IS NOT NULL
),
ship_fee_ratio_quartiles AS (
    -- NTILE(4): chia don theo ty le phi ship/gia hang tang dan.
    SELECT metric_value, review_score,
           NTILE(4) OVER (ORDER BY metric_value) AS quartile_number
    FROM ship_fee_ratio_data
),
ship_fee_summary AS (
    SELECT
        'Tổng phí ship (BRL)' AS chi_so,
        CASE quartile_number
            WHEN 1 THEN 'Nhóm 1 - 25% phí thấp nhất'
            WHEN 2 THEN 'Nhóm 2 - từ 25%-50%'
            WHEN 3 THEN 'Nhóm 3 - từ 50%-75%'
            ELSE 'Nhóm 4 - 25% phí cao nhất'
        END AS nhom_quartile,
        COUNT(*) AS so_don,
        ROUND(AVG(metric_value), 2) AS gia_tri_trung_binh,
        ROUND(AVG(review_score), 2) AS diem_review_trung_binh
    FROM ship_fee_quartiles
    GROUP BY quartile_number
),
ship_fee_ratio_summary AS (
    SELECT
        'Tỷ lệ phí ship/giá hàng (%)' AS chi_so,
        CASE quartile_number
            WHEN 1 THEN 'Nhóm 1 - 25% tỷ lệ thấp nhất'
            WHEN 2 THEN 'Nhóm 2 - từ 25%-50%'
            WHEN 3 THEN 'Nhóm 3 - từ 50%-75%'
            ELSE 'Nhóm 4 - 25% tỷ lệ cao nhất'
        END AS nhom_quartile,
        COUNT(*) AS so_don,
        ROUND(AVG(metric_value), 2) AS gia_tri_trung_binh,
        ROUND(AVG(review_score), 2) AS diem_review_trung_binh
    FROM ship_fee_ratio_quartiles
    GROUP BY quartile_number
)
SELECT * FROM ship_fee_summary
UNION ALL
SELECT * FROM ship_fee_ratio_summary
ORDER BY chi_so DESC, nhom_quartile;


-- ============================================================
-- Q5: DO PHUC TAP DON HANG - SO SAN PHAM VA SO NGUOI BAN
-- ============================================================
SELECT
    CASE
        WHEN item_count = 1 THEN '1 mat hang'
        WHEN item_count BETWEEN 2 AND 3 THEN '2-3 mat hang'
        ELSE '4+ mat hang'
    END AS basket_group,
    CASE
        WHEN seller_count = 1 THEN '1 nguoi ban'
        ELSE 'Nhieu nguoi ban'
    END AS seller_group,
    COUNT(*) AS order_count,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    ROUND(100.0 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 2) AS low_score_pct
FROM v_review_order_features
GROUP BY basket_group, seller_group
ORDER BY MIN(item_count), MIN(seller_count);


-- ============================================================
-- Q6: PHUONG THUC THANH TOAN VA SO KY TRA GOP
-- ============================================================
SELECT
    first_payment_type AS payment_type,
    COUNT(*) AS order_count,
    ROUND(AVG(max_installments), 2) AS avg_installments,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    ROUND(100.0 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 2) AS low_score_pct
FROM v_review_order_features
WHERE first_payment_type IS NOT NULL
GROUP BY first_payment_type
ORDER BY order_count DESC;

SELECT
    CASE
        WHEN max_installments <= 1 THEN '1 ky / tra mot lan'
        WHEN max_installments BETWEEN 2 AND 6 THEN '2-6 ky'
        WHEN max_installments BETWEEN 7 AND 12 THEN '7-12 ky'
        ELSE 'Hon 12 ky'
    END AS installment_group,
    COUNT(*) AS order_count,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    ROUND(100.0 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 2) AS low_score_pct
FROM v_review_order_features
WHERE max_installments IS NOT NULL
GROUP BY installment_group
ORDER BY MIN(max_installments);


-- ============================================================
-- Q7: XU HUONG REVIEW SCORE THEO THANG (22 THANG DU LIEU)
-- ============================================================
SELECT
    purchase_year_month,
    COUNT(*) AS order_count,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    ROUND(100.0 * AVG(CASE WHEN review_score >= 4 THEN 1 ELSE 0 END), 2) AS positive_pct,
    ROUND(100.0 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 2) AS low_score_pct
FROM v_review_order_features

GROUP BY purchase_year_month
ORDER BY purchase_year_month;


-- ============================================================
-- Q8: MUC DO HAI LONG THEO BANG/KHU VUC
-- Chi bao gom bang co toi thieu 100 don.
-- ============================================================
SELECT
    customer_state,
    COUNT(*) AS order_count,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    ROUND(100.0 * AVG(CASE WHEN review_score >= 4 THEN 1 ELSE 0 END), 2) AS positive_pct,
    ROUND(100.0 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 2) AS low_score_pct,
    ROUND(AVG(is_late) * 100.0, 2) AS late_rate_pct,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days
FROM v_review_order_features
GROUP BY customer_state
HAVING COUNT(*) >= 100
ORDER BY avg_review_score ASC, low_score_pct DESC;



