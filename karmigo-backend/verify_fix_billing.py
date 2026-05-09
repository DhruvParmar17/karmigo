import urllib.request
import json

url = "http://127.0.0.1:8000/billing/estimate"
payload = {
  "labour_count": 1,
  "floor_no": 2,
  "lift_available": True,
  "walking_distance_meters": 50,
  "hours_requested": 2.0,
  "house_size": "1BHK",
  "special_items_count": 2,
  "service_charge_type": "heavy_lifting",
  "work_type": "shifting",
  "heavy_items": {"fridge": 1}
}

try:
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req) as response:
        print(f"Status Code: {response.status}")
        if response.status == 200:
            print("Response JSON:")
            print(json.dumps(json.loads(response.read().decode('utf-8')), indent=2))
        else:
            print(f"Error: {response.read()}")
except urllib.error.HTTPError as e:
    print(f"HTTP Error: {e.code} {e.reason}")
    print(e.read().decode('utf-8'))
except Exception as e:
    print(f"Connection Error: {e}")
