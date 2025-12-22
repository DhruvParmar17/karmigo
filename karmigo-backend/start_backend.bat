@echo off
cd /d "C:\Users\dhurv\karmigo-backend"
call venv\Scripts\activate
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

