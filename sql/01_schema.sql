-- ============================================================
-- DATABASE SCHEMA: OLIST E-COMMERCE ANALYSIS
-- Target DBMS : SQLite 3.x
-- Architecture: Staging → Relational (3NF) → Views
-- Nhóm        : ADY291c-AI2107-Group2
-- ============================================================

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;   -- tăng hiệu năng ghi đồng thời

-- ============================================================
-- PHẦN 1: BẢNG STAGING (1-1 với CSV processed, import nhanh)
-- ============================================================

CREATE TABLE IF NOT EXISTS stg_customers (
    customer_id              TEXT,
    customer_unique_id       TEXT,
    customer_zip_code_prefix INTEGER,
    customer_city            TEXT,
    customer_state           TEXT
);

CREATE TABLE IF NOT EXISTS stg_orders (
    order_id                      TEXT,
    customer_id                   TEXT,
    order_status                  TEXT,
    order_purchase_timestamp      TEXT,
    order_approved_at             TEXT,
    order_delivered_carrier_date  TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT,
    delivery_days                 REAL,
    estimated_days                REAL,
    delay_days                    INTEGER,
    is_late                       INTEGER,   -- 0/1 (SQLite không có BOOL)
    purchase_year                 INTEGER,
    purchase_month                INTEGER,
    purchase_year_month           TEXT,
    purchase_weekday              INTEGER,
    purchase_hour                 INTEGER
);

CREATE TABLE IF NOT EXISTS stg_order_items (
    order_id         TEXT,
    order_item_id    INTEGER,
    product_id       TEXT,
    seller_id        TEXT,
    shipping_limit_date TEXT,
    price            REAL,
    freight_value    REAL,
    is_price_outlier INTEGER,   -- 0/1
    item_total       REAL
);

CREATE TABLE IF NOT EXISTS stg_order_payments (
    order_id              TEXT,
    payment_sequential    INTEGER,
    payment_type          TEXT,
    payment_installments  INTEGER,
    payment_value         REAL
);

CREATE TABLE IF NOT EXISTS stg_order_reviews (
    review_id               TEXT,
    order_id                TEXT,
    review_score            INTEGER,
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TEXT,
    review_answer_timestamp TEXT,
    has_comment             INTEGER   -- 0/1
);

CREATE TABLE IF NOT EXISTS stg_products (
    product_id                 TEXT,
    product_category_name      TEXT,
    product_name_length        REAL,
    product_description_length REAL,
    product_photos_qty         REAL,
    product_weight_g           REAL,
    product_length_cm          REAL,
    product_height_cm          REAL,
    product_width_cm           REAL,
    product_volume_cm3         REAL
);

CREATE TABLE IF NOT EXISTS stg_sellers (
    seller_id               TEXT,
    seller_zip_code_prefix  INTEGER,
    seller_city             TEXT,
    seller_state            TEXT
);

CREATE TABLE IF NOT EXISTS stg_geolocations (
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat             REAL,
    geolocation_lng             REAL,
    geolocation_city            TEXT,
    geolocation_state           TEXT
);

CREATE TABLE IF NOT EXISTS stg_product_categories (
    product_category_name         TEXT,
    product_category_name_english TEXT
);


-- ============================================================
-- PHẦN 2: BẢNG QUAN HỆ CHUẨN HÓA (3NF)
-- ============================================================

-- ------------------------------------------------------------
-- 2.1 PRODUCT_CATEGORIES — Bảng tra cứu danh mục sản phẩm
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product_categories (
    product_category_name         TEXT PRIMARY KEY,
    product_category_name_english TEXT NOT NULL
);

-- ------------------------------------------------------------
-- 2.2 GEOLOCATIONS — Bảng tra cứu mã bưu chính / toạ độ
-- (1 zip_code → 1 bản ghi đại diện trung bình lat/lng)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS geolocations (
    zip_code_prefix INTEGER PRIMARY KEY,
    lat             REAL,
    lng             REAL,
    city            TEXT,
    state           TEXT
);

-- ------------------------------------------------------------
-- 2.3 CUSTOMERS — Khách hàng
-- customer_id   : mã phiên (1 người mua nhiều lần = nhiều customer_id)
-- customer_unique_id : mã thực sự của người dùng
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    customer_id              TEXT PRIMARY KEY,
    customer_unique_id       TEXT NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city            TEXT,
    customer_state           TEXT,
    FOREIGN KEY (customer_zip_code_prefix)
        REFERENCES geolocations(zip_code_prefix) ON DELETE SET NULL
);

-- ------------------------------------------------------------
-- 2.4 SELLERS — Người bán
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sellers (
    seller_id              TEXT PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city            TEXT,
    seller_state           TEXT,
    FOREIGN KEY (seller_zip_code_prefix)
        REFERENCES geolocations(zip_code_prefix) ON DELETE SET NULL
);

-- ------------------------------------------------------------
-- 2.5 PRODUCTS — Sản phẩm
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    product_id                 TEXT PRIMARY KEY,
    product_category_name      TEXT,
    product_name_length        REAL,
    product_description_length REAL,
    product_photos_qty         INTEGER,
    product_weight_g           REAL,
    product_length_cm          REAL,
    product_height_cm          REAL,
    product_width_cm           REAL,
    product_volume_cm3         REAL,
    FOREIGN KEY (product_category_name)
        REFERENCES product_categories(product_category_name) ON DELETE SET NULL
);

-- ------------------------------------------------------------
-- 2.6 ORDERS — Đơn hàng (trung tâm của star schema)
-- Giữ lại cột engineered (delivery_days, is_late, ...) để
-- tối ưu query phân tích — Denormalization có kiểm soát.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    order_id                      TEXT PRIMARY KEY,
    customer_id                   TEXT NOT NULL,
    order_status                  TEXT NOT NULL DEFAULT 'delivered',
    order_purchase_timestamp      TEXT NOT NULL,
    order_approved_at             TEXT,
    order_delivered_carrier_date  TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT,
    -- Cột tính toán (engineered features từ preprocessing)
    delivery_days                 REAL,
    estimated_days                REAL,
    delay_days                    INTEGER DEFAULT 0,
    is_late                       INTEGER DEFAULT 0 CHECK(is_late IN (0, 1)),
    purchase_year                 INTEGER,
    purchase_month                INTEGER,
    purchase_year_month           TEXT,
    purchase_weekday              INTEGER,
    purchase_hour                 INTEGER,
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- 2.7 ORDER_ITEMS — Chi tiết sản phẩm trong đơn hàng
-- Composite PK: 1 đơn có thể gồm nhiều sản phẩm
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_items (
    order_id         TEXT    NOT NULL,
    order_item_id    INTEGER NOT NULL,
    product_id       TEXT    NOT NULL,
    seller_id        TEXT    NOT NULL,
    shipping_limit_date TEXT,
    price            REAL    NOT NULL DEFAULT 0,
    freight_value    REAL    NOT NULL DEFAULT 0,
    is_price_outlier INTEGER DEFAULT 0 CHECK(is_price_outlier IN (0, 1)),
    item_total       REAL    NOT NULL DEFAULT 0,
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id)   ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE SET NULL,
    FOREIGN KEY (seller_id)  REFERENCES sellers(seller_id)  ON DELETE SET NULL
);

-- ------------------------------------------------------------
-- 2.8 ORDER_PAYMENTS — Thanh toán (1 đơn có thể nhiều lần TT)
-- Composite PK: (order_id, payment_sequential)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_payments (
    order_id             TEXT    NOT NULL,
    payment_sequential   INTEGER NOT NULL,
    payment_type         TEXT    NOT NULL,
    payment_installments INTEGER DEFAULT 1,
    payment_value        REAL    NOT NULL DEFAULT 0,
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- 2.9 ORDER_REVIEWS — Đánh giá của khách hàng
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_reviews (
    review_id               TEXT    PRIMARY KEY,
    order_id                TEXT    NOT NULL,
    review_score            INTEGER NOT NULL CHECK(review_score BETWEEN 1 AND 5),
    review_comment_title    TEXT    DEFAULT 'No Title',
    review_comment_message  TEXT    DEFAULT 'No Comment',
    review_creation_date    TEXT,
    review_answer_timestamp TEXT,
    has_comment             INTEGER DEFAULT 0 CHECK(has_comment IN (0, 1)),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);


-- ============================================================
-- PHẦN 3: INDEX TỐI ƯU HOÁ TRUY VẤN
-- ============================================================

-- orders → tra cứu theo khách, thời gian, trạng thái trễ
CREATE INDEX IF NOT EXISTS idx_orders_customer    ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_purchase_ts ON orders(order_purchase_timestamp);
CREATE INDEX IF NOT EXISTS idx_orders_year_month  ON orders(purchase_year_month);
CREATE INDEX IF NOT EXISTS idx_orders_is_late     ON orders(is_late);

-- order_items → JOIN phổ biến nhất
CREATE INDEX IF NOT EXISTS idx_items_order    ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_items_product  ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_items_seller   ON order_items(seller_id);

-- order_payments → aggregate theo order
CREATE INDEX IF NOT EXISTS idx_payments_order ON order_payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_type  ON order_payments(payment_type);

-- order_reviews → JOIN + filter theo score
CREATE INDEX IF NOT EXISTS idx_reviews_order ON order_reviews(order_id);
CREATE INDEX IF NOT EXISTS idx_reviews_score ON order_reviews(review_score);

-- products → JOIN với category
CREATE INDEX IF NOT EXISTS idx_products_category ON products(product_category_name);

-- customers/sellers → JOIN với geolocation
CREATE INDEX IF NOT EXISTS idx_customers_zip ON customers(customer_zip_code_prefix);
CREATE INDEX IF NOT EXISTS idx_customers_state ON customers(customer_state);
CREATE INDEX IF NOT EXISTS idx_sellers_state ON sellers(seller_state);




