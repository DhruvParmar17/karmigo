
import os
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY = os.getenv("KARMIGO_SECRET_KEY", "karmigo-secret-key-change-this")
ALGORITHM = os.getenv("KARMIGO_ALGORITHM", "HS256")
