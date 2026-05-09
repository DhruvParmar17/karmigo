
import asyncio
import httpx
import uuid

BASE_URL = "http://127.0.0.1:8000"

# Use existing admin credentials or force one
ADMIN_EMAIL = "admin@karmigo.com" 
ADMIN_PASSWORD = "password123" # Assuming default or previously created

async def run_verification():
    async with httpx.AsyncClient() as client:
        # 1. Login Admin
        print("--- 1. Auth Admin ---")
        # Ensure admin user exists (might need manual creation if not seeded, but let's try login)
        resp = await client.post(f"{BASE_URL}/auth/login", json={"email": "1234@gmail.com", "password": "password"}) # Known admin from code analysis
        
        if resp.status_code != 200:
            print(f"Login FAILED: {resp.text}. Tying Signup...")
            await client.post(f"{BASE_URL}/auth/signup", json={"email": "1234@gmail.com", "password": "password", "full_name": "Admin User"})
            resp = await client.post(f"{BASE_URL}/auth/login", json={"email": "1234@gmail.com", "password": "password"})
            
            if resp.status_code != 200:
                 print(f"Signup/Login FAILED: {resp.text}")
                 return

        token = resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        
        # 2. Get Labours
        print("--- 2. Get Labour List ---")
        resp = await client.get(f"{BASE_URL}/labour/all", headers=headers)
        if resp.status_code == 200:
            labours = resp.json()['labour']
            print(f"Labours Found: {len(labours)}")
            if len(labours) > 0:
                labour_id = labours[0]['id']
                
                # 3. Toggle Verification
                print(f"--- 3. Toggle Verification for {labour_id} ---")
                current_ver = labours[0].get('is_verified', False)
                
                # Check if PUT /labour/{id} works
                resp = await client.put(f"{BASE_URL}/labour/{labour_id}", json={"is_verified": not current_ver}, headers=headers)
                if resp.status_code == 200:
                    print(f"Update OK: {resp.json()['labour']['is_verified']}")
                else:
                    print(f"Update FAIL: {resp.status_code} {resp.text}")

        else:
             print(f"Get Labour FAIL: {resp.status_code}")


if __name__ == "__main__":
    asyncio.run(run_verification())
