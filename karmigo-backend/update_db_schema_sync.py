import psycopg2
import logging

# Config
DB_HOST="localhost" # Or 'db' if inside docker, but we are running from host?
# Wait, user path is c:\Users\dhurv... so we are on Host.
# Docker port mapping is 5433:5432 in docker-compose.yml.
# "postgresql+asyncpg://karmigouser:dhrsan@localhost:5433/karmigo"
DB_PORT=5433
DB_NAME="karmigo"
DB_USER="karmigouser"
DB_PASS="dhrsan"

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def add_columns():
    try:
        logger.info(f"Connecting to DB at {DB_HOST}:{DB_PORT}...")
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        conn.autocommit = True
        cur = conn.cursor()

        # Check latitude
        try:
            cur.execute("SELECT latitude FROM orders LIMIT 1")
            logger.info("'latitude' column exists.")
        except psycopg2.Error:
            conn.rollback()
            logger.info("Adding 'latitude'...")
            cur.execute("ALTER TABLE orders ADD COLUMN latitude FLOAT DEFAULT NULL")
            logger.info("Added 'latitude'.")
        
        # Check longitude
        try:
            cur.execute("SELECT longitude FROM orders LIMIT 1")
            logger.info("'longitude' column exists.")
        except psycopg2.Error:
            conn.rollback()
            logger.info("Adding 'longitude'...")
            cur.execute("ALTER TABLE orders ADD COLUMN longitude FLOAT DEFAULT NULL")
            logger.info("Added 'longitude'.")

        # Check required_labours
        try:
            cur.execute("SELECT required_labours FROM orders LIMIT 1")
            logger.info("'required_labours' column exists.")
        except psycopg2.Error:
            conn.rollback()
            logger.info("Adding 'required_labours'...")
            cur.execute("ALTER TABLE orders ADD COLUMN required_labours INTEGER DEFAULT 1")
            logger.info("Added 'required_labours'.")

        cur.close()
        conn.close()
        logger.info("Done.")

    except Exception as e:
        logger.error(f"Error: {e}")

if __name__ == "__main__":
    add_columns()
