
import requests
import json

BASE_URL = "http://127.0.0.1:8000"
EMAIL = "sansritidubey49@gmail.com"
PASSWORD = "bromie03"

def debug_flow():
    # 1. Login
    print("Logging in...")
    resp = requests.post(f"{BASE_URL}/auth/login", json={"email": EMAIL, "password": PASSWORD})
    if resp.status_code != 200:
        print(f"Login Failed: {resp.text}")
        return
    token = resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    print("Login successful.")

    # 2. Get Jobs
    print("Fetching jobs...")
    resp = requests.get(f"{BASE_URL}/jobs/", headers=headers)
    if resp.status_code != 200:
        print(f"Fetch Jobs Failed: {resp.text}")
        return
    
    jobs = resp.json()
    pending_jobs = [j for j in jobs if j["order_status"] == "pending"]
    
    if not pending_jobs:
        print("No pending jobs to accept.")
        return

    job_to_accept = pending_jobs[0]
    job_id = job_to_accept["id"]
    print(f"Attempting to accept job: {job_id}")

    # 3. Assign Job
    resp = requests.put(f"{BASE_URL}/jobs/{job_id}/assign", headers=headers)
    print(f"Response Status: {resp.status_code}")
    print(f"Response Body: {resp.text}")

if __name__ == "__main__":
    debug_flow()
