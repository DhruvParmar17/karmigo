# app/main.py

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.db import database
from app.api.jobs import router as jobs_router
from app.api.auth import router as auth_router
from app.api.users import router as users_router
from app.api.labour import router as labour_router

app = FastAPI(title="Karmigo Backend")

# ---- CORS (frontend can call backend) ----
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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

# Optional root route
@app.get("/")
def home():
    return {"message": "Karmigo Backend Running"}
