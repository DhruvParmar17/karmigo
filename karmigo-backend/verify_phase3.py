
import asyncio
import httpx
import uuid

BASE_URL = "http://127.0.0.1:8000"
SUFFIX = str(uuid.uuid4())[:8]
LABOUR_EMAIL = f"labour_p3_{SUFFIX}@test.com"
PASSWORD = "password123"

async def run_verification():
    async with httpx.AsyncClient() as client:
        # 1. Signup Labour
        print("--- 1. Auth ---")
        await client.post(f"{BASE_URL}/auth/signup", json={"email": LABOUR_EMAIL, "password": PASSWORD, "full_name": "Labour P3"})
        resp = await client.post(f"{BASE_URL}/auth/login", json={"email": LABOUR_EMAIL, "password": PASSWORD})
        
        if resp.status_code != 200:
            print(f"Login FAILED: {resp.text}")
            return

        token = resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        
        # 2. Check Wallet Balance
        print("--- 2. Wallet Balance ---")
        resp = await client.get(f"{BASE_URL}/labour/wallet/balance", headers=headers)
        if resp.status_code == 200:
            print(f"Balance: {resp.json()}")
        else:
            print(f"Wallet Balance FAILED: {resp.status_code} {resp.text}")

        # 3. Check Wallet Transactions
        print("--- 3. Wallet Transactions ---")
        resp = await client.get(f"{BASE_URL}/labour/wallet/transactions", headers=headers)
        if resp.status_code == 200:
            print(f"Transactions: {len(resp.json())}")
        else:
            print(f"Wallet Transactions FAILED: {resp.status_code} {resp.text}")

if __name__ == "__main__":
    asyncio.run(run_verification())
