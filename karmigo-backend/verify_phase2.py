
import asyncio
import httpx
import uuid

BASE_URL = "http://127.0.0.1:8000"
SUFFIX = str(uuid.uuid4())[:8]
CUSTOMER_EMAIL = f"cust_p2_{SUFFIX}@test.com"
PASSWORD = "password123"

async def run_verification():
    async with httpx.AsyncClient() as client:
        # 1. Signup & Login
        print("--- 1. Auth ---")
        await client.post(f"{BASE_URL}/auth/signup", json={"email": CUSTOMER_EMAIL, "password": PASSWORD})
        resp = await client.post(f"{BASE_URL}/auth/login", json={"email": CUSTOMER_EMAIL, "password": PASSWORD})
        token = resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        
        # 2. Create Job
        print("--- 2. Create Job ---")
        resp = await client.post(f"{BASE_URL}/jobs/", json={
            "title": "To be cancelled",
            "description": "desc",
            "location": "loc",
            "work_type": "shifting",
            "labour_count": 1
        }, headers=headers)
        
        if resp.status_code not in [200, 201]:
             print(f"Create Job FAILED: {resp.status_code} {resp.text}")
             return

        job_id = resp.json()["id"]
        print(f"Job Created: {job_id}")

        # 3. Cancel Job
        print("--- 3. Cancel Job ---")
        resp = await client.post(f"{BASE_URL}/jobs/{job_id}/cancel", headers=headers)
        if resp.status_code == 200:
            print("Cancel OK")
            j = resp.json()
            if j["order_status"] != "cancelled":
                print(f"FAIL: Job status is {j['order_status']}")
        else:
            print(f"Cancel FAILED: {resp.text}")

        # 4. Delete Job
        print("--- 4. Delete Job ---")
        resp = await client.delete(f"{BASE_URL}/jobs/{job_id}", headers=headers)
        if resp.status_code == 204: # No Content
            print("Delete OK (204)")
        else:
            print(f"Delete FAILED: {resp.status_code} {resp.text}")

        # 5. Verify Deletion
        print("--- 5. Verify Deletion ---")
        resp = await client.get(f"{BASE_URL}/jobs/{job_id}", headers=headers)
        if resp.status_code == 404:
            print("Verify OK: Job Not Found")
        else:
            print(f"Verify FAIL: Job still exists? {resp.status_code}")

if __name__ == "__main__":
    asyncio.run(run_verification())
