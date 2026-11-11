@echo off
setlocal
cd /d "%~dp0"

set "PYTHON_EXE="
set "PYTHON_ARGS="

if exist "%~dp0.venv\Scripts\python.exe" (
    set "PYTHON_EXE=%~dp0.venv\Scripts\python.exe"
    call :check_environment
    if not errorlevel 1 goto launch
)
if exist "%~dp0.venv313\Scripts\python.exe" (
    set "PYTHON_EXE=%~dp0.venv313\Scripts\python.exe"
    call :check_environment
    if not errorlevel 1 goto launch
)

py -3.13 -c "import streamlit, pandas, numpy, plotly, sklearn, joblib" >nul 2>&1
if not errorlevel 1 (
    set "PYTHON_EXE=py"
    set "PYTHON_ARGS=-3.13"
    goto launch
)

echo Python with the dashboard packages was not found.
echo Please follow the one-time setup instructions in README.md.
pause
exit /b 1

:launch
echo Starting the Olist dashboard. Keep this window open while using the app.
"%PYTHON_EXE%" %PYTHON_ARGS% -m streamlit run dashboard\app.py
if errorlevel 1 (
    echo.
    echo The dashboard stopped with an error.
    pause
)
exit /b

:check_environment
"%PYTHON_EXE%" %PYTHON_ARGS% -c "import streamlit, pandas, numpy, plotly, sklearn, joblib" >nul 2>&1
exit /b %errorlevel%
