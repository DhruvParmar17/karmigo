
import asyncio
import httpx
import uuid

BASE_URL = "http://127.0.0.1:8000"
LAB_EMAIL = f"lab_debug_{str(uuid.uuid4())[:6]}@test.com"
PWD = "password123"

async def run():
    async with httpx.AsyncClient() as client:
        print(f"1. Signup: {LAB_EMAIL}")
        res = await client.post(f"{BASE_URL}/auth/signup", json={"email": LAB_EMAIL, "password": PWD, "full_name": "Debug Lab"})
        print(f"Signup Status: {res.status_code}")
        print(f"Signup Resp: {res.text}")

        print("2. Add Profile")
        profile = {
            "full_name": "Debug Lab",
            "email": LAB_EMAIL,
            "phone": "0000000000",
            "skills": "Test",
            "rating": 5.0,
            "wallet_balance": 0.0, 
            "is_verified": True
        }
        res = await client.post(f"{BASE_URL}/labour/add", json=profile)
        print(f"Add Profile Status: {res.status_code}")
        print(f"Add Profile Resp: {res.text}")

        print("3. Login")
        res = await client.post(f"{BASE_URL}/auth/login", json={"email": LAB_EMAIL, "password": PWD})
        print(f"Login Status: {res.status_code}")
        if res.status_code == 200:
            print(f"Login Role: {res.json().get('role')}")
        else:
            print(f"Login Resp: {res.text}")

if __name__ == "__main__":
    asyncio.run(run())
