"""
run_queries.py - Chạy 8 câu truy vấn SQL Q01-Q08 và xuất báo cáo Markdown.
Nhom: ADY291c-AI2107-Group2
"""

import os
import sqlite3
import sys
import time
from pathlib import Path

import pandas as pd


if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")


BASE_DIR = Path(__file__).resolve().parents[2]
DB_PATH = BASE_DIR / "scripts" / "database" / "olist.db"
SQL_PATH = BASE_DIR / "sql" / "03_queries.sql"
REPORT_PATH = BASE_DIR / "data" / "processed" / "sql_business_report.md"


def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA cache_size = -64000")
    conn.execute("PRAGMA mmap_size = 268435456")
    conn.execute("PRAGMA temp_store = MEMORY")
    return conn


def run_query(conn, title, sql, max_rows=50):
    print("\n" + "=" * 70)
    print(f"{title}")
    print("=" * 70)

    started_at = time.time()
    df = pd.read_sql_query(sql, conn)
    elapsed = time.time() - started_at

    print(f"Thoi gian thuc hien: {elapsed:.3f}s | So dong: {len(df)}")
    print(df.head(max_rows).to_string(index=False))
    if len(df) > max_rows:
        print(f"... con {len(df) - max_rows} dong trong bao cao Markdown")
    return df


def export_report(reports, report_path):
    report_path.parent.mkdir(parents=True, exist_ok=True)
    sections = ["# Báo cáo truy vấn SQL Q01-Q08 - Olist\n"]
    for title, dataframe in reports:
        sections.append(f"\n## {title}\n")
        sections.append(f"\nSố dòng kết quả: {len(dataframe)}\n")
        sections.append("\n" + dataframe.to_markdown(index=False) + "\n")
    report_path.write_text("".join(sections), encoding="utf-8")

def initialize_views(conn):
    if not SQL_PATH.exists():
        raise FileNotFoundError(f"Khong tim thay {SQL_PATH}")
    conn.executescript(SQL_PATH.read_text(encoding="utf-8"))


QUERIES = [
    (
        "Q01: Phân bố điểm đánh giá và mức mất cân bằng lớp",
        """
        SELECT review_score,
               COUNT(*) AS order_count,
               ROUND(100.0 * COUNT(*) /
                     (SELECT COUNT(*) FROM v_review_order_features), 2) AS percentage
        FROM v_review_order_features
        GROUP BY review_score
        ORDER BY review_score;
        """,
    ),
    (
        "Q02: Đơn giao trễ so với đúng hạn",
        """
        SELECT CASE WHEN is_late = 1 THEN 'Giao trễ'
                    ELSE 'Đúng hạn hoặc sớm' END AS delivery_group,
               COUNT(*) AS order_count,
               ROUND(AVG(review_score), 2) AS avg_review_score,
               ROUND(100.0 * AVG(CASE WHEN review_score >= 4 THEN 1 ELSE 0 END), 2) AS positive_pct,
               ROUND(100.0 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 2) AS low_score_pct
        FROM v_review_order_features
        GROUP BY is_late
        ORDER BY delivery_group;
        """,
    ),
    (
        "Q03: Mức độ trễ theo nhóm ngày",
        """
        SELECT CASE
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
        """,
    ),
    (
        "Q04: Phí ship và tỷ lệ phí trên giá hàng",
        """
        WITH ship_fee_data AS (
            SELECT total_freight AS metric_value, review_score
            FROM v_review_order_features
        ),
        ship_fee_quartiles AS (
            -- NTILE(4) chia tung don thanh 4 nhom phi ship gan bang nhau.
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
            -- NTILE(4) chia tung don theo ty le phi ship/gia tri hang hoa.
            SELECT metric_value, review_score,
                   NTILE(4) OVER (ORDER BY metric_value) AS quartile_number
            FROM ship_fee_ratio_data
        ),
        ship_fee_summary AS (
            SELECT 'Tổng phí ship (BRL)' AS chi_so,
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
            SELECT 'Tỷ lệ phí ship/giá hàng (%)' AS chi_so,
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
        """,
    ),
    (
        "Q05: Độ phức tạp của đơn hàng",
        """
        SELECT CASE
                   WHEN item_count = 1 THEN '1 mat hang'
                   WHEN item_count BETWEEN 2 AND 3 THEN '2-3 mat hang'
                   ELSE '4+ mat hang'
               END AS basket_group,
               CASE WHEN seller_count = 1 THEN '1 nguoi ban'
                    ELSE 'Nhieu nguoi ban' END AS seller_group,
               COUNT(*) AS order_count,
               ROUND(AVG(review_score), 2) AS avg_review_score,
               ROUND(100.0 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 2) AS low_score_pct
        FROM v_review_order_features
        GROUP BY basket_group, seller_group
        ORDER BY MIN(item_count), MIN(seller_count);
        """,
    ),
    (
        "Q06: Thanh toán và trả góp",
        """
        SELECT first_payment_type AS payment_type,
               COUNT(*) AS order_count,
               ROUND(AVG(max_installments), 2) AS avg_installments,
               ROUND(AVG(review_score), 2) AS avg_review_score,
               ROUND(100.0 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 2) AS low_score_pct
        FROM v_review_order_features
        WHERE first_payment_type IS NOT NULL
        GROUP BY first_payment_type
        ORDER BY order_count DESC;
        """,
    ),
    (
        "Q07: Xu hướng review theo tháng",
        """
        SELECT purchase_year_month,
               COUNT(*) AS order_count,
               ROUND(AVG(review_score), 2) AS avg_review_score,
               ROUND(100.0 * AVG(CASE WHEN review_score >= 4 THEN 1 ELSE 0 END), 2) AS positive_pct,
               ROUND(100.0 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 2) AS low_score_pct
        FROM v_review_order_features
        GROUP BY purchase_year_month
        ORDER BY purchase_year_month;
        """,
    ),
    (
        "Q08: Hài lòng theo bang/khu vực",
        """
        SELECT customer_state,
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
        """,
    ),
]


def main():
    if not DB_PATH.exists():
        print(f"Khong tim thay database: {DB_PATH}")
        print("Hay chay: python scripts\\database\\build_db.py")
        return

    conn = get_connection()
    required_tables = (
        "customers", "orders", "order_items", "order_payments",
        "order_reviews", "products", "sellers",
    )
    empty_tables = [
        table for table in required_tables
        if conn.execute(f'SELECT COUNT(*) FROM "{table}"').fetchone()[0] == 0
    ]
    if empty_tables:
        conn.close()
        print("Database chua co du du lieu: " + ", ".join(empty_tables))
        print("Hay chay: python scripts\\database\\build_db.py")
        return

    initialize_views(conn)

    reports = []
    print("BẮT ĐẦU 8 CÂU TRUY VẤN SQL Q01-Q08...")
    for title, sql in QUERIES:
        reports.append((title, run_query(conn, title, sql)))
    
    conn.close()


if __name__ == "__main__":
    main()
