import asyncio
import sys
import logging
import json
import urllib.request
import urllib.error
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy.future import select
from app.db.models import User

# Logging
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)

# DB Configs
DB_OPTIONS = [
    "postgresql+asyncpg://karmigouser:dhrsan@db:5432/karmigo",          # Internal Docker
    "postgresql+asyncpg://karmigouser:dhrsan@localhost:5433/karmigo", # Docker mapped
    "postgresql+asyncpg://karmigouser:dhrsan@localhost:5432/karmigo"  # Local
]

API_URL = "http://localhost:8000/auth/signup"

async def promote_email(email, session):
    email = email.lower().strip()
    logger.info(f"Checking DB for user: {email}")
    query = select(User).where(User.email == email)
    result = await session.execute(query)
    user = result.scalar_one_or_none()
    
    if user:
        if user.is_superuser:
            logger.info(f" -> User {email} is ALREADY Admin.")
        else:
            user.is_superuser = True
            session.add(user)
            await session.commit()
            logger.info(f" -> SUCCESS: Promoted {email} to Admin.")
    else:
        logger.warning(f" -> User {email} NOT FOUND in this DB.")

async def run_db_updates():
    emails_to_promote = ["sansritidubey4@gmail.com", "1234@gmail.com"]
    
    for db_url in DB_OPTIONS:
        logger.info(f"--- Connecting to DB: {db_url} ---")
        try:
            engine = create_async_engine(db_url, echo=False)
            async_session_maker = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
            
            async with async_session_maker() as session:
                for email in emails_to_promote:
                    await promote_email(email, session)
            
            await engine.dispose()
            logger.info("--- DB Connection Closed ---\n")
        except Exception as e:
            logger.error(f"Failed to connect to {db_url}: {e}\n")

def perform_signup():
    payload = {
        "email": "sansritidubey4@gmail.com",
        "password": "sansriti",
        "full_name": "Admin Sansriti"
    }
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(API_URL, data=data, headers={'Content-Type': 'application/json'})
    
    logger.info(f"Attempting Signup for {payload['email']}...")
    try:
        with urllib.request.urlopen(req) as response:
            logger.info(f"Signup Response: {response.status} {response.read().decode()}")
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        if "already registered" in body:
             logger.info("User already registered (This is good).")
        else:
             logger.error(f"Signup Request Failed: {e.code} {body}")
    except Exception as e:
        logger.error(f"Signup Error: {e}")

if __name__ == "__main__":
    # 1. Signup
    perform_signup()
    
    # 2. Promote
    if sys.platform == 'win32':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(run_db_updates())
