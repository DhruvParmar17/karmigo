
from app.services.billing_service import BillingService

def verify_estimate():
    print("--- 1. Verify Base Rate (1 Labour) ---")
    est = BillingService.calculate_estimate(
        labour_count=1,
        floor_no=0,
        lift_available=True,
        walking_distance_meters=0,
        heavy_items_json="{}"
    )
    print(f"Estimate (1 Labour): {est['total_estimated_amount']}")
    assert est['total_estimated_amount'] == 350.0, f"Expected 350.0, got {est['total_estimated_amount']}"

    print("--- 2. Verify Base Rate (2 Labours) ---")
    est_2 = BillingService.calculate_estimate(
        labour_count=2,
        floor_no=0,
        lift_available=True,
        walking_distance_meters=0,
        heavy_items_json="{}"
    )
    print(f"Estimate (2 Labours): {est_2['total_estimated_amount']}")
    assert est_2['total_estimated_amount'] == 700.0, f"Expected 700.0, got {est_2['total_estimated_amount']}"
    
    print("--- 3. Verify Heavy Item Calculation ---")
    est_heavy = BillingService.calculate_estimate(
        labour_count=1,
        floor_no=0,
        lift_available=True,
        walking_distance_meters=0,
        heavy_items_json='{"fridge": 1}'
    )
    # 350 (base) + 80 (fridge) = 430
    print(f"Estimate (1 Labour + Fridge): {est_heavy['total_estimated_amount']}")
    assert est_heavy['total_estimated_amount'] == 430.0, f"Expected 430.0, got {est_heavy['total_estimated_amount']}"

    print("\nBilling Verification SUCCESS")

if __name__ == "__main__":
    verify_estimate()
