import requests
import json

BASE_URL = "http://localhost:8000"

def test_get_jobs():
    print(f"Testing GET {BASE_URL}/jobs/ ...")
    try:
        # Assuming we can access without auth for public list or we need a token?
        # jobs.py: list_jobs depends on get_current_user.
        # We need a token.
        
        # 1. Login to get token (using a known user or creating one?)
        # Let's try to login with a test user if possible, or just hit the public endpoint if any.
        # But list_jobs is protected.
        
        # I'll rely on the existing token or try to login.
        # Let's try listing WITHOUT auth first, expect 401.
        response = requests.get(f"{BASE_URL}/jobs/")
        print(f"Response calling /jobs/ without auth: {response.status_code}")
        
        if response.status_code == 401:
            print("✅ Auth correctly enforced. Now we need a token to test the 500 error.")
            # We need to login.
            # Assuming 'customer@example.com' / 'password' or similar exists?
            # Or I can try to Signup a temp user.
            email = "test_diag_user@example.com"
            password = "password123"
            
            print(f"Attempting Signup/Login with {email}...")
            # Try signup
            requests.post(f"{BASE_URL}/auth/signup", json={"email": email, "password": password})
            # Login
            login_res = requests.post(f"{BASE_URL}/auth/login", json={"email": email, "password": password})
            
            if login_res.status_code == 200:
                token = login_res.json()["access_token"]
                print("✅ Login successful. Got token.")
                
                # Now List Jobs
                headers = {"Authorization": f"Bearer {token}"}
                jobs_res = requests.get(f"{BASE_URL}/jobs/?order_status=pending", headers=headers)
                
                print(f"GET /jobs/ Status: {jobs_res.status_code}")
                if jobs_res.status_code != 200:
                    print("❌ GET /jobs/ Failed!")
                    print("Response Body:", jobs_res.text)
                else:
                    print("✅ GET /jobs/ Success!")
                    print(f"Got {len(jobs_res.json())} jobs.")
            else:
                print(f"❌ Login failed: {login_res.text}")

    except Exception as e:
        print(f"❌ Connection failed: {e}")

if __name__ == "__main__":
    test_get_jobs()
