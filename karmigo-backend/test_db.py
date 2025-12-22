# debug/test_db.py
import psycopg2
import os
from dotenv import load_dotenv
import traceback

load_dotenv()

# Read env (and strip whitespace just in case)
DB_HOST = os.getenv("DB_HOST", "").strip()
DB_PORT = os.getenv("DB_PORT", "").strip()
DB_NAME = os.getenv("DB_NAME", "").strip()
DB_USER = os.getenv("DB_USER", "").strip()
DB_PASS = os.getenv("DB_PASS", "").strip()

print("DEBUG: values Python read (quotes show exact content):")
print(f"  DB_HOST = '{DB_HOST}'")
print(f"  DB_PORT = '{DB_PORT}' (type {type(DB_PORT)})")
print(f"  DB_NAME = '{DB_NAME}'")
print(f"  DB_USER = '{DB_USER}'")
print(f"  DB_PASS = '{DB_PASS}'")

# Make port an int (psycopg2 accepts int)
try:
    PORT_INT = int(DB_PORT) if DB_PORT != "" else None
except Exception as e:
    print("ERROR: DB_PORT is not an integer:", e)
    PORT_INT = None

# Helper to show full exception info
def show_exc(e):
    print("Exception repr:", repr(e))
    try:
        print("pgcode:", getattr(e, 'pgcode', None))
        print("pgerror:", getattr(e, 'pgerror', None))
    except Exception:
        pass
    traceback.print_exc()

# Attempt 1: normal connect using host/port
try:
    print("\nAttempt 1: psycopg2.connect(host, port) ...")
    conn = psycopg2.connect(
        host=DB_HOST or "127.0.0.1",
        port=PORT_INT or 5432,
        dbname=DB_NAME or "karmigo",
        user=DB_USER,
        password=DB_PASS,
        connect_timeout=5
    )
    print("✅ Attempt 1: Connection successful!")
    conn.close()
    raise SystemExit(0)  # success - stop here
except Exception as e:
    print("❌ Attempt 1 failed:")
    show_exc(e)

# Attempt 2: connection string (host.docker.internal) fallback
try:
    host_str = f"host=host.docker.internal port={DB_PORT} dbname={DB_NAME} user={DB_USER} password={DB_PASS}"
    print("\nAttempt 2: psql connection string (host.docker.internal) ...")
    print("  connection string (masked):", f"host=host.docker.internal port={DB_PORT} dbname={DB_NAME} user={DB_USER} password=***")
    conn = psycopg2.connect(host_str)
    print("✅ Attempt 2: Connection successful!")
    conn.close()
    raise SystemExit(0)
except Exception as e:
    print("❌ Attempt 2 failed:")
    show_exc(e)

print("\nAll attempts failed. Paste the above output in the chat and I'll read it.")
