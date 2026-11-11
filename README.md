# ADY291c_AI2107_GROUP2

## Overview

This project analyzes the Olist Brazilian e-commerce dataset using Python, SQL, and Streamlit.

## Data
Bộ dữ liệu được sử dụng: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

## Python setup (Windows)

The project is tested with Python 3.13. Install Python 3.13 with the official Python Install Manager, then create a virtual environment from the repository root:

```powershell
py install 3.13
py -3.13 --version
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

In VS Code, select the `.venv` interpreter and choose its Python kernel when opening a notebook.

Run commands from the repository root so the scripts can find the `data` and `sql` directories:

```powershell
# Start the Streamlit dashboard
streamlit run dashboard\app.py

# Rebuild the SQLite database from cleaned CSV files
.\.venv\Scripts\python.exe scripts\database\build_db.py

# Run the SQL business queries (requires data\olist.db)
python scripts\database\run_queries.py

```

`build_db.py` replaces the existing `data\olist.db` after a successful build. The cleaned CSV files must be present in `data\processed` before running it; if they are missing, run the preprocessing notebook in `Notebooks Project`.

## Present the project with Streamlit

The dashboard is designed to run locally from the repository root:

1. Follow the Python setup above once, then open a PowerShell terminal in this project folder.
2. Activate the environment and start the app:

   ```powershell
   .\.venv\Scripts\Activate.ps1
   python -m streamlit run dashboard\app.py
   ```

3. Open the local URL printed in the terminal (usually `http://localhost:8501`).
4. Choose **Chế độ Thuyết trình** to move through the seven project slides, or **Chế độ Dashboard Tương tác** to explore all sections. Use the sidebar to filter by purchase year, customer state, and delivery status. Toggle speaker notes on or off for presentation practice.

The dashboard reads `data\processed\olist_master.csv` locally. The repository also includes the compressed `data\processed\olist_master.csv.gz` copy used by Streamlit Community Cloud. Saved figures in `report\figures` are used when available; otherwise the dashboard builds charts from the filtered data.

The **Dự đoán nguy cơ review thấp** mode provides two Random Forest models: one predicts before delivery, and the other after delivery. Both estimate the risk of a review score of **1–2 stars**; they do not predict an exact 1–5 star score. The serialized models were created with scikit-learn 1.9.1, so that version is pinned in `requirements.txt`.

## Deploy to Streamlit Community Cloud

1. Push the project to a GitHub repository that your account can administer (for example, your own fork). The deployment needs `dashboard/app.py`, `data\processed\olist_master.csv.gz`, and both `.joblib` model files under `Notebooks Project\4_REGRESSION ANALYSIS AND MACHINE LEARNING PREDICTION`.
2. In Streamlit Community Cloud, create an app from that repository and branch.
3. Set **Main file path** to `dashboard/app.py` (not `streamlit_app.py`).
4. In Advanced settings, choose Python 3.13, then deploy. Streamlit installs the dependencies from `requirements.txt`.

The full SQLite database is not required by the deployed dashboard.

## Team Members
- Phùng Văn Tráng - HE200218
- Nguyễn Văn Khanh - HE200414
- Lê Quốc Trung - HE204010

## Technologies
- Python
- Pandas, NumPy
- Scikit-learn
- Matplotlib, Seaborn
