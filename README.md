# ADY291c_AI2107_GROUP1

## Overview

This project analyzes the Olist Brazilian e-commerce dataset using Python, SQL, and Streamlit.

## Data
Bộ dữ liệu được sử dụng: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

## Python setup (Windows)

The project is tested with Python 3.13. Install Python 3.13 with the official Python Install Manager, then create a virtual environment from the repository root:

```powershell
py install 3.13
py -3.13 --version
py -3.13 -m venv .venv313
.\.venv313\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

In VS Code, select the `.venv313` interpreter and choose its Python kernel when opening a notebook.

Run commands from the repository root so the scripts can find the `data` and `sql` directories:

```powershell
# Start the Streamlit dashboard
streamlit run dashboard\app.py

# Rebuild the SQLite database from cleaned CSV files
.\.venv313\Scripts\python.exe scripts\database\build_db.py

# Run the SQL business queries (requires data\olist.db)
python scripts\database\run_queries.py

```

`build_db.py` replaces the existing `data\olist.db` after a successful build. The cleaned CSV files must be present in `data\processed` before running it; if they are missing, run the preprocessing notebook in `Notebooks Project`.

## Present the project with Streamlit

To start the dashboard without entering a command, double-click `Chay_dashboard.bat` in the project folder. It opens the dashboard in your browser; keep the command window open while presenting, and close it when finished.

For the first run on a new computer, complete the one-time Python setup above. You can also start the app manually from a terminal in the project folder:

```powershell
.\.venv313\Scripts\python.exe -m streamlit run dashboard\app.py
```

The Streamlit app is focused only on predicting review risk. Choose whether to predict before or after delivery, enter the order details, and select **Dự đoán nguy cơ review**. Both Random Forest models estimate the risk of a review score of **1–2 stars**; they do not predict an exact 1–5 star score. The serialized models were created with scikit-learn 1.9.1, so that version is pinned in `requirements.txt`. The dashboard does not need the processed CSV files or SQLite database.

## Deploy to Streamlit Community Cloud

1. Push the project to a GitHub repository that your account can administer (for example, your own fork). The deployment needs `dashboard/app.py` and both `.joblib` model files under `Notebooks Project\4_REGRESSION ANALYSIS AND MACHINE LEARNING PREDICTION`.
2. In Streamlit Community Cloud, create an app from that repository and branch.
3. Set **Main file path** to `dashboard/app.py` (not `streamlit_app.py`).
4. In Advanced settings, choose Python 3.13, then deploy. Streamlit installs the dependencies from `requirements.txt`.

## Team Members
- Phùng Văn Tráng - HE200218
- Nguyễn Văn Khanh - HE200414
- Lê Quốc Trung - HE204010

## Technologies
- Python
- Pandas, NumPy
- Scikit-learn
- Matplotlib, Seaborn
