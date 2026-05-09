import urllib.request
import json
key = "AIzaSyDf0vXoO2XhFoHxNEj0Cln1uo2Jmw0wuBM"
url = f"https://maps.googleapis.com/maps/api/geocode/json?address=Mumbai&key={key}"
try:
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read().decode())
        print(f"Status: {data.get('status')}")
        if 'error_message' in data:
            print(f"Error: {data['error_message']}")
except Exception as e:
    print(f"Exception: {e}")
