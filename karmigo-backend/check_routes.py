import sys
import os

# Ensure backend folder is in path
sys.path.append(os.getcwd())

from app.main import app

print("Checking routes...")
found = False
for route in app.routes:
    if hasattr(route, "path") and "send-otp" in route.path:
        print(f"FOUND: {route.path} [{route.methods}]")
        found = True

if not found:
    print("NOT FOUND: send-otp route is missing!")
else:
    print("Routes verified.")
