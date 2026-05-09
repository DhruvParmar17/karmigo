# app/main.py
from dotenv import load_dotenv
import os

load_dotenv()  # loads .env file

GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY")

print(GOOGLE_MAPS_API_KEY)  # (temporary, just to test)

# Force reload
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.db import database
from app.api.jobs import router as jobs_router
from app.api.auth import router as auth_router
from app.api.users import router as users_router
from app.api.labour import router as labour_router
from app.api.admin import router as admin_router
from app.api.billing import router as billing_router

app = FastAPI(title="Karmigo Backend")

# ---- CORS (frontend can call backend) ----
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex="https?://(localhost|127\.0\.0\.1)(:[0-9]+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---- Startup ----
@app.on_event("startup")
async def on_startup():
    print("🚀 Starting Karmigo Backend...")
    await database.init_db()
    print("✅ Database connected & initialized!")

# ---- Shutdown ----
@app.on_event("shutdown")
async def on_shutdown():
    await database.close_db()
    print("🛑 Karmigo Backend stopped.")

# ---- Routers ----
app.include_router(auth_router)       # prefix already inside auth.py
app.include_router(users_router)      # prefix inside users.py
app.include_router(jobs_router)       # prefix inside jobs.py
app.include_router(labour_router)     # prefix inside labour.py
app.include_router(admin_router)      # prefix inside admin.py
app.include_router(billing_router)    # prefix inside billing.py
from app.api.maps import router as maps_router
app.include_router(maps_router)


# Optional root route
@app.get("/")
def home():
    return {"message": "Karmigo Backend Running"}
