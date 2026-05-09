
from fastapi import APIRouter
import httpx
import os

router = APIRouter(prefix="/maps", tags=["maps"])

GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY") or "AIzaSyDf0vXoO2XhFoHxNEj0Cln1uo2Jmw0wuBM"

@router.get("/autocomplete")
async def autocomplete_proxy(input: str):
    """
    Proxy Google Places Autocomplete to avoid CORS on web
    """
    url = f"https://maps.googleapis.com/maps/api/place/autocomplete/json?input={input}&key={GOOGLE_MAPS_API_KEY}"
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(url)
            return resp.json()
    except Exception as e:
        print(f"Error fetching autocomplete: {e}")
        return {"status": "ERROR", "error_message": str(e)}

@router.get("/details")
async def details_proxy(place_id: str):
    """
    Proxy Google Places Details to avoid CORS on web
    """
    url = f"https://maps.googleapis.com/maps/api/place/details/json?place_id={place_id}&key={GOOGLE_MAPS_API_KEY}"
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(url)
            return resp.json()
    except Exception as e:
         print(f"Error fetching place details: {e}")
         return {"status": "ERROR", "error_message": str(e)}
