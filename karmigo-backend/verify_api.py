import requests
import json
import random

BASE_URL = "http://127.0.0.1:8000"

def verify_api():
    # 1. Signup/Login to get Token
    email = f"verifier_{random.randint(1000,9999)}@test.com"
    password = "password123"
    
    print(f"Attempting to signup with {email}...")
    try:
        signup_res = requests.post(f"{BASE_URL}/auth/signup", json={
            "email": email,
            "password": password,
            "full_name": "Verifier",
            "phone": "9999999999"
        })
        
        if signup_res.status_code not in [200, 201]:
           print(f"Signup failed (might exist): {signup_res.status_code}")
           
        print("Logging in...")
        login_res = requests.post(f"{BASE_URL}/auth/login", json={
            "email": email,
            "password": password
        })
        
        if login_res.status_code != 200:
            print(f"Login failed: {login_res.text}")
            return
            
        token = login_res.json().get("access_token")
        headers = {"Authorization": f"Bearer {token}"}
        print("Authenticated.")

        # 2. List Jobs
        url = f"{BASE_URL}/jobs/"
        print(f"Requesting {url}...")
        response = requests.get(url, params={"limit": 10}, headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            with open("api_response.txt", "w") as f:
                 f.write(f"Listed {len(data)} jobs. Now checking specific job...\n")
            
            # Check specific job
            job_id = "92221f83-5d56-40a4-9484-5c1ea20dd98d"
            res_single = requests.get(f"{BASE_URL}/jobs/{job_id}", headers=headers)
            if res_single.status_code == 200:
                job = res_single.json()
                print(f"Specfic Job {job_id}:")
                print(f"Title: {job.get('title')}")
                print(f"Status: {job.get('order_status')}")
                print(f"Total Amount: {job.get('total_amount')}")
                print(f"Required Labours: {job.get('required_labours')}")
                print(f"Accepted Count: {job.get('accepted_labours_count')}")
                print(f"Per Labour Gross: {job.get('per_labour_gross')}")
                print(f"Per Labour Net: {job.get('per_labour_net')}")
                
                with open("api_response.txt", "a") as f:
                    f.write(f"--- SPECIFIC JOB {job_id} ---\n")
                    f.write(f"Title: {job.get('title')}\n")
                    f.write(f"Total Amount: {job.get('total_amount')}\n")
                    f.write(f"Required Labours: {job.get('required_labours')}\n")
                    f.write(f"Accepted Count: {job.get('accepted_labours_count')}\n")
                    f.write(f"Per Gross: {job.get('per_labour_gross')}\n")
                    f.write(f"Per Net: {job.get('per_labour_net')}\n")
                    f.write(f"Per Earning (New): {job.get('per_labour_earning')}\n")
            else:
                print(f"Failed to fetch job {job_id}: {res_single.status_code}")

        else:
            print(f"Error: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"Failed to connect: {e}")



if __name__ == "__main__":
    verify_api()

