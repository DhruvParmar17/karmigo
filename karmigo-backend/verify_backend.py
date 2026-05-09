import requests
import sys

BASE_URL = "http://127.0.0.1:8000"

def check_backend():
    print(f"Checking backend at {BASE_URL}...")
    try:
        # Check Root
        resp = requests.get(f"{BASE_URL}/")
        print(f"Root: {resp.status_code} {resp.json()}")
        
        # Check Jobs (Auth required usually, so might fail 401, which is GOOD)
        resp = requests.get(f"{BASE_URL}/jobs/")
        print(f"Jobs: {resp.status_code}")
        
        if resp.status_code == 401:
            print("Backend is UP (Auth correctly rejected).")
        elif resp.status_code == 200:
            print("Backend is UP (Jobs reachable).")
        else:
            print(f"Backend is UP but returned {resp.status_code}")
            
    except Exception as e:
        print(f"CRITICAL: Backend unreachable. Error: {e}")
        print("Please restart the backend server: 'uvicorn app.main:app --reload'")

if __name__ == "__main__":
    check_backend()
