
import unittest
import json
from datetime import datetime, timedelta
from app.services.billing_service import BillingService

class TestBillingService(unittest.TestCase):
    def test_basic_estimate(self):
        # 1 Labour, 1 Hour (implicit in base), No heavy items, Ground floor
        estimate = BillingService.calculate_estimate(
            labour_count=1,
            floor_no=0,
            lift_available=True,
            walking_distance_meters=0,
            heavy_items_json="{}"
        )
        self.assertEqual(estimate["base_price"], 200.0)
        self.assertEqual(estimate["total_estimated_amount"], 200.0)

    def test_heavy_items(self):
        # 1 Labour, Fridge (80)
        estimate = BillingService.calculate_estimate(
            labour_count=1,
            floor_no=0,
            lift_available=True,
            walking_distance_meters=0,
            heavy_items_json=json.dumps({"fridge": 1})
        )
        self.assertEqual(estimate["heavy_item_charges"], 80.0)
        self.assertEqual(estimate["total_estimated_amount"], 280.0)

    def test_floor_charges(self):
        # 1 Labour, 3rd Floor (No lift) -> (3-2)=1 floor charge. * Items?
        # Requires heavy items to charge per floor per item.
        # 1 Fridge.
        estimate = BillingService.calculate_estimate(
            labour_count=1,
            floor_no=3,
            lift_available=False,
            walking_distance_meters=0,
            heavy_items_json=json.dumps({"fridge": 1})
        )
        # Base: 200
        # Heavy: 80
        # Floor: 7 * 1 (floor) * 1 (item) = 7
        self.assertEqual(estimate["floor_charges_estimate"], 7.0)
        self.assertEqual(estimate["total_estimated_amount"], 287.0)

    def test_walking_charges(self):
        # 1 Labour, 100 meters (>50). Extra 50m. 1 Unit.
        # Rate 30 per 50m per labour.
        estimate = BillingService.calculate_estimate(
            labour_count=1,
            floor_no=0,
            lift_available=True,
            walking_distance_meters=100,
            heavy_items_json="{}"
        )
        # Base: 200
        # Walking: 30 * 1 unit * 1 labour = 30
        self.assertEqual(estimate["walking_charges_estimate"], 30.0)
        self.assertEqual(estimate["total_estimated_amount"], 230.0)

    def test_final_bill_time(self):
        start = datetime.now()
        end = start + timedelta(minutes=90) # 1.5 hours. Base 60. Extra 30.
        
        estimate_data = {"total_estimated_amount": 200.0}
        
        bill = BillingService.calculate_final_bill(
            estimate_data=estimate_data,
            started_at=start,
            ended_at=end,
            labour_count=1
        )
        
        # Base covered 60 mins.
        # Extra 30 mins -> 1 block.
        # Rate 50 per 30 mins per labour.
        # Total time cost = 50.
        self.assertEqual(bill["labour_cost_time_final"], 50.0)
        self.assertEqual(bill["total_final_amount"], 250.0)

if __name__ == "__main__":
    unittest.main()
