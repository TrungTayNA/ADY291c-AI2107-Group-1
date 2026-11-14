# ADY291c_AI2107_GROUP2

## Team Members

- Phùng Văn Tráng - HE200218(Group leader)
- Nguyễn Văn Khanh - HE200414
- Lê Quốc Trung - HE204010

## Technologies

- Python
- Pandas, NumPy
- Scikit-learn
- Matplotlib, Seaborn
- SQLite

## Overview

This project analyzes the Olist Brazilian e-commerce dataset using Python, SQL, and machine learning. It explores delivery delays and customer reviews, visualizes the data, and evaluates models for identifying orders associated with low review scores.

## Data

The project uses the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

## Python setup (Windows)

The project uses Python 3.13. Install Python 3.13 with the official Python Install Manager, then create a virtual environment from the repository root:

```powershell
py install 3.13
py -3.13 --version
py -3.13 -m venv .venv313
.\.venv313\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

In VS Code, select the `.venv313` interpreter and choose its Python kernel when opening a notebook.

Run commands from the repository root. The notebooks locate the project folders relative to the repository, and the SQLite import script can also be run from the root:

```powershell
.\.venv313\Scripts\python.exe SQL_Analysis\import_to_sqlite.py
```

## Technologies

- Python
- Pandas, NumPy
- Scikit-learn
- Matplotlib, Seaborn
- SQLite

## Project workflow

Run the notebooks in the following order:

1. **Collect, explore, and preprocess data**

   Open `Notebooks Project/2_DATA COLLECTION, EXPLORATION, AND PREPROCESSING/02_data_collection_exploration_preprocessing.ipynb` and run its cells. The notebook reads the raw CSV files and creates:
   - `data/processed/olist_model_dataset.csv`
   - `data/processed/olist_analysis_dataset.csv`

2. **Load data into SQLite**

   Run the import command above after the preprocessing notebook has created `olist_model_dataset.csv`. It creates or replaces the `olist_model_dataset` table in `SQL_Analysis/olist_analysis.db`.

3. **Analyze data with SQL**

   Open `Notebooks Project/3_DATA ANALYSIS USING SQL AND PYTHON/03_sql_analysis.ipynb` to run the SQLite analyses. The related standalone SQL query files are in `SQL_Analysis/`:
   - `01_delivery_analysis.sql`
   - `02_item_count_analysis.sql`
   - `03_delay_group_analysis.sql`
   - `04_combined_analysis.sql`

4. **Visualize the data**

   Open and run `Notebooks Project/3_DATA ANALYSIS USING SQL AND PYTHON/04_data_visualization.ipynb`. It reads `data/processed/olist_analysis_dataset.csv`.

5. **Train and evaluate prediction models**

   Open and run `Notebooks Project/4_REGRESSION ANALYSIS AND MACHINE LEARNING PREDICTION/05_machine_learning_prediction.ipynb`. It reads `data/processed/olist_model_dataset.csv` and compares Logistic Regression with Random Forest for predicting low reviews.

### Input data

Before running the preprocessing notebook, make sure these Olist CSV files are in `data/raw/`:

- `olist_orders_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_order_reviews_dataset.csv`

Download them from the dataset linked above if they are not already available locally. The preprocessing notebook generates the processed CSV files; rerun it whenever the raw input data changes.

## Project structure

```text
Notebooks Project/
  2_DATA COLLECTION, EXPLORATION, AND PREPROCESSING/
  3_DATA ANALYSIS USING SQL AND PYTHON/
  4_REGRESSION ANALYSIS AND MACHINE LEARNING PREDICTION/
SQL_Analysis/
  01_delivery_analysis.sql
  02_item_count_analysis.sql
  03_delay_group_analysis.sql
  04_combined_analysis.sql
  import_to_sqlite.py
data/
  raw/
  processed/
report/
  figures/
```

## Team Members

- Phùng Văn Tráng - HE200218
- Nguyễn Văn Khanh - HE200414
- Lê Quốc Trung - HE204010

## Technologies

- Python
- Pandas, NumPy
- Scikit-learn
- Matplotlib, Seaborn
- SQLite
