import asyncio
import asyncpg

async def main():
    conn = await asyncpg.connect('postgresql://karmigouser:dhrsan@localhost:5433/karmigo')
    try:
        await conn.execute('ALTER TABLE users ADD COLUMN IF NOT EXISTS address VARCHAR;')
        print('Successfully added address column to users table.')
    except Exception as e:
        print(f'Error: {e}')
    finally:
        await conn.close()

if __name__ == '__main__':
    asyncio.run(main())
