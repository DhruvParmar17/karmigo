@echo off
cd /d "C:\Users\dhurv\karmigo\karmigo-backend"
venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

