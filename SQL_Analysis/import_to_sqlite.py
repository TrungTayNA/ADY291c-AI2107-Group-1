"""Import the processed Olist model dataset into a SQLite database."""

import sqlite3
from pathlib import Path

import pandas as pd

# Build paths from this file location, so the script runs from any working directory
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent

# The CSV is stored in data/processed; Data/ is accepted as an alternative location
CSV_CANDIDATES = [
    PROJECT_DIR / "data" / "processed" / "olist_model_dataset.csv",
    PROJECT_DIR / "Data" / "olist_model_dataset.csv",
]
CSV_PATH = next((path for path in CSV_CANDIDATES if path.is_file()), None)
if CSV_PATH is None:
    raise FileNotFoundError("Khong tim thay olist_model_dataset.csv trong data/processed hoac Data/")

DB_PATH = SCRIPT_DIR / "olist_analysis.db"

# 1. Read the processed dataset
df = pd.read_csv(CSV_PATH)

# 2. Open (or create) the database and load the table
conn = sqlite3.connect(DB_PATH)
df.to_sql("olist_model_dataset", conn, if_exists="replace", index=False)

# 3. Check the number of rows inside the database
rows_in_db = conn.execute("SELECT COUNT(*) FROM olist_model_dataset").fetchone()[0]

# 4. Close the connection
conn.close()

print(f"CSV file   : {CSV_PATH}")
print(f"Database   : {DB_PATH}")
print(f"Rows in CSV    : {len(df)}")
print(f"Rows in SQLite : {rows_in_db}")
print(f"Columns        : {list(df.columns)}")
