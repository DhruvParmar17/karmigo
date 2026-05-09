import sys
import os
import math
from datetime import datetime

# Add current directory to path so we can import app
sys.path.append(os.getcwd())

try:
    from app.services.billing_service import BillingService
    print("✅ Successfully imported BillingService")
except ImportError as e:
    print(f"❌ Failed to import BillingService: {e}")
    sys.exit(1)

def test_calculate_estimate():
    print("\n--------------------------")
    print("Testing calculate_estimate")
    print("--------------------------")
    
    # Mock inputs similar to what billing.py passes
    try:
        estimate = BillingService.calculate_estimate(
            labour_count=2,
            floor_no=3,
            lift_available=False,
            walking_distance_meters=100,
            hours_requested=2.5,
            house_size="2BHK",
            special_items_count=2,
            service_charge_type="heavy_lifting"
            # is_night_shift default False
        )
        
        print("✅ Estimate calculated successfully")
        print(f"Keys returned: {list(estimate.keys())}")
        
        # Verify required keys for billing.py
        required_keys = [
            "base_price", "labour_cost_time_estimate", "floor_charges_estimate",
            "distance_charge_estimate", "service_charge_estimate",
            "special_items_charge_estimate", "house_size_charge",
            "gst_amount", "platform_fee", "per_labour_earning",
            "total_estimated_amount"
        ]
        
        missing = [k for k in required_keys if k not in estimate]
        if missing:
            print(f"❌ Missing keys required by billing.py: {missing}")
        else:
            print("✅ All required keys present")
            
        return estimate
    except Exception as e:
        print(f"❌ calculate_estimate failed: {e}")
        import traceback
        traceback.print_exc()
        return None

def test_billing_logic_simulation(estimate):
    print("\n--------------------------")
    print("Testing billing.py assignment logic (simulation)")
    print("--------------------------")
    
    if not estimate:
        print("❌ input estimate is None, skipping")
        return

    try:
        # Simulate the assignments in billing.py
        data = {
            "base_price": estimate.get("base_price", 0.0),
            "labour_cost_time_estimate": estimate.get("labour_cost_time_estimate", 0.0),
            "floor_charges_estimate": estimate.get("floor_charges_estimate", 0.0),
            "walking_charges_estimate": estimate.get("distance_charge_estimate", 0.0),
            
            "service_charge_estimate": estimate.get("service_charge_estimate", 0.0),
            "special_items_charge_estimate": estimate.get("special_items_charge_estimate", 0.0),
            "house_size_charge": estimate.get("house_size_charge", 0.0),
            "distance_charge_estimate": estimate.get("distance_charge_estimate", 0.0),
            
            "gst_amount": estimate.get("gst_amount", 0.0),
            "platform_fee": estimate.get("platform_fee", 0.0),
            "per_labour_earning": estimate.get("per_labour_earning", 0.0),
            
            "total_estimated_amount": estimate.get("total_estimated_amount", 0.0)
        }
        
        print(f"✅ Data assignment successful: {data}")
    except Exception as e:
        print(f"❌ Data assignment failed: {e}")

if __name__ == "__main__":
    est = test_calculate_estimate()
    test_billing_logic_simulation(est)
