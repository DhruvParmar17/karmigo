import requests
import uuid
import time

BASE_URL = "http://localhost:8000"

def test_auto_registration():
    # 1. Signup a NEW User (Who is NOT a Labour yet)
    new_email = f"auto_labour_{uuid.uuid4()}@example.com"
    password = "password123"
    
    print(f"Signing up new user: {new_email}")
    resp = requests.post(f"{BASE_URL}/auth/signup", json={
        "email": new_email,
        "password": password,
        "full_name": "New Auto Labour"
    })
    if resp.status_code != 200:
        print("Signup failed:", resp.text)
        return
    print("User signup successful.")

    # 2. Login
    # EXPECTATION: At this point, role might be "customer" because they haven't been created in Labour table yet.
    # OR if we updated auth.py, maybe it's labour. But we didn't update auth.py to auto-create yet.
    # We only updated deps.py (lazy). So login should say "customer" or "labour_id": null.
    pass_resp = requests.post(f"{BASE_URL}/auth/login", json={
        "email": new_email,
        "password": password
    })
    login_data = pass_resp.json()
    print("Initial Login Role:", login_data.get("role"))
    
    token = login_data["access_token"]

    # 3. Create a Job (as a customer)
    cust_email = f"cust_{uuid.uuid4()}@example.com"
    requests.post(f"{BASE_URL}/auth/signup", json={"email": cust_email, "password": "password", "full_name": "Cust"})
    cust_login = requests.post(f"{BASE_URL}/auth/login", json={"email": cust_email, "password": "password"}).json()
    cust_token = cust_login["access_token"]
    
    job_resp = requests.post(f"{BASE_URL}/jobs/", json={
        "title": "Fresh Job",
        "description": "Auto assign test",
        "location": "Test Lab",
        "price": 50.0
    }, headers={"Authorization": f"Bearer {cust_token}"})
    
    job_id = job_resp.json()["id"]
    print(f"Job created: {job_id}")
    
    # 4. Accept Job (This triggers the auto-registration in deps.py)
    print("Attempting to accept job (should trigger auto-registration)...")
    assign_resp = requests.put(
        f"{BASE_URL}/jobs/{job_id}/assign",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    if assign_resp.status_code == 200:
        print("SUCCESS! Job assigned.")
        print("Response:", assign_resp.json())
        
        # 5. Verify Labour Record Exists now
        # Login again to see if role is now 'labour'
        login_again = requests.post(f"{BASE_URL}/auth/login", json={
            "email": new_email,
            "password": password
        }).json()
        print("Re-Login Role:", login_again.get("role"))
        if login_again.get("role") == "labour" and login_again.get("labour_id"):
             print("Verified: User is now permanently a labour.")
        else:
             print("Warning: User role not updated in login?")
    else:
        print("FAILED to assign job:", assign_resp.status_code, assign_resp.text)

if __name__ == "__main__":
    try:
        test_auto_registration()
    except Exception as e:
        print(f"Error: {e}")
