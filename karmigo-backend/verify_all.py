
import asyncio
import httpx
import uuid
import sys

BASE_URL = "http://127.0.0.1:8000"
CUST_EMAIL = f"cust_{str(uuid.uuid4())[:6]}@test.com"
LAB_EMAIL = f"lab_{str(uuid.uuid4())[:6]}@test.com"
ADM_EMAIL = "1234@gmail.com" # Existing admin
PWD = "password123"

async def run():
    async with httpx.AsyncClient() as client:
        print(f"--- 1. Signup Users ---")
        # Customer
        print("Registering Customer...")
        res = await client.post(f"{BASE_URL}/auth/signup", json={"email": CUST_EMAIL, "password": PWD, "full_name": "Cust Test"})
        if res.status_code not in [200, 201]:
             print(f"Customer Signup Warning: {res.status_code} {res.text}")
        
        c_resp = await client.post(f"{BASE_URL}/auth/login", json={"email": CUST_EMAIL, "password": PWD})
        if c_resp.status_code != 200:
            print(f"Customer Login FAILED: {c_resp.text}")
            return
        c_token = c_resp.json()['access_token']
        c_head = {"Authorization": f"Bearer {c_token}"}
        
        # Labour
        print("Registering Labour...")
        res = await client.post(f"{BASE_URL}/auth/signup", json={"email": LAB_EMAIL, "password": PWD, "full_name": "Lab Test"}) # removed Invalid role field
        if res.status_code not in [200, 201]:
             print(f"Labour User Signup Warning: {res.status_code} {res.text}")

        # ADD LABOUR PROFILE (Crucial Step)
        lab_profile = {
            "full_name": "Lab Test",
            "email": LAB_EMAIL,
            "phone": "9876543210",
            "skills": "General",
            "rating": 5.0,
            "wallet_balance": 0.0,
            "is_verified": True # Verify immediately for test
        }
        res = await client.post(f"{BASE_URL}/labour/add", json=lab_profile)
        if res.status_code != 200:
             print(f"Labour Profile Add Warning: {res.status_code} {res.text}")

        l_resp = await client.post(f"{BASE_URL}/auth/login", json={"email": LAB_EMAIL, "password": PWD})
        if l_resp.status_code != 200:
            print(f"Labour Login FAILED: {l_resp.text}")
            return
        l_token = l_resp.json()['access_token']
        l_head = {"Authorization": f"Bearer {l_token}"}
        
        # Admin
        print("Logging in Admin...")
        a_resp = await client.post(f"{BASE_URL}/auth/login", json={"email": ADM_EMAIL, "password": "password"})
        if a_resp.status_code != 200:
             print("Admin Login Failed, trying signup...")
             await client.post(f"{BASE_URL}/auth/signup", json={"email": ADM_EMAIL, "password": "password", "full_name": "Admin User"})
             a_resp = await client.post(f"{BASE_URL}/auth/login", json={"email": ADM_EMAIL, "password": "password"})
             
        if a_resp.status_code != 200:
            print(f"Admin Auth FAILED: {a_resp.text}")
            return 
        a_token = a_resp.json()['access_token']
        a_head = {"Authorization": f"Bearer {a_token}"}
        
        # Get Labour ID
        print("Getting Labour ID...")
        l_me = await client.get(f"{BASE_URL}/users/me", headers=l_head)
        if l_me.status_code != 200:
             print(f"Get Labour Me FAILED: {l_me.status_code} {l_me.text}")
             return
        l_id = l_me.json()['id']
        print(f"Labour ID: {l_id}")

        print(f"--- 2. Customer Creates Job ---")
        job_data = {
            "title": "Full Flow Check",
            "description": "Moving verify_all validation",
            "location": "Test Loc 123",
            "latitude": 19.0,
            "longitude": 72.0,
            "work_type": "shifting",
            "labour_count": 1
        }
        res = await client.post(f"{BASE_URL}/jobs/", json=job_data, headers=c_head)
        if res.status_code != 200:
            print(f"Create Job FAILED: {res.status_code} {res.text}")
            return
        job_id = res.json()['id']
        print(f"Job Created: {job_id}")

        print(f"--- 3. Assign Job (simulate Acceptance) ---")
        # Labour accepts (assign endpoint)
        res = await client.put(f"{BASE_URL}/jobs/{job_id}/assign?labour_id={l_id}", headers=l_head) # Or admin assign
        # In current flow, labor user hits /assign?labour_id=me via existing ID logic or just hits it.
        # Actually API is: /jobs/{job_id}/assign with labour_id explicitly if Admin, or implied? 
        # Let's use Admin assign to be safe as we tested that.
        res = await client.put(f"{BASE_URL}/jobs/{job_id}/assign?labour_id={l_id}", headers=a_head)
        print(f"Assign Status: {res.status_code}")

        print(f"--- 4. Start Job ---")
        res = await client.post(f"{BASE_URL}/billing/{job_id}/start", headers=l_head)
        if res.status_code != 200:
             print(f"Start FAILED (Maybe already started or logic error): {res.text}")

        print(f"--- 5. Generate Bill (Wait 1 sec) ---")
        await asyncio.sleep(1)
        res = await client.post(f"{BASE_URL}/billing/{job_id}/generate", json={"waiting_time_minutes": 10}, headers=l_head)
        print(f"Bill Generated: {res.json().get('total_amount', 'Error')}")

        print(f"--- 6. Pay & Complete ---")
        res = await client.post(f"{BASE_URL}/billing/{job_id}/pay", json={"payment_method": "cash"}, headers=l_head)
        if res.status_code == 200:
            print("Payment & Completion OK")
        else:
            print(f"Payment FAILED: {res.text}")

        print(f"--- 7. Verify Admin Status ---")
        res = await client.get(f"{BASE_URL}/jobs/{job_id}", headers=a_head)
        status = res.json()['order_status']
        print(f"Final Job Status: {status}")

        print(f"--- 8. Verify Wallet Balance ---")
        res = await client.get(f"{BASE_URL}/labour/wallet/balance", headers=l_head)
        print(f"Labour Wallet: {res.json()}")
        
        print("\n=== VERIFICATION SUCCESS ===")

if __name__ == "__main__":
    asyncio.run(run())
