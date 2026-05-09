import math
import json
from datetime import datetime

# Pricing Constants
BASE_RATE_PER_LABOUR = 350.0 # First 1 hour
BASE_TIME_MINUTES = 60

EXTRA_TIME_RATE_PER_BLOCK = 50.0  # Per labour per 30 mins
EXTRA_TIME_BLOCK_MINUTES = 30

WAITING_FREE_MINUTES = 15
WAITING_RATE_PER_MIN_PER_LABOUR = 5.0 # After 15 mins

# Floor Charges
FLOOR_RATE_LIFT = 3.0 # Per floor per labour
FLOOR_RATE_NO_LIFT = 10.0 # Per floor per labour
# Note: Prompt says "per floor (per labour)". 
# "If lift available: ₹3 per floor per labour"
# "If no lift: ₹10 per floor per labour"
# Old logic was "per item". New logic is just per floor per labour.

# House Size Charges (Fixed added once)
HOUSE_SIZE_CHARGES = {
    "1RK": 0.0,
    "1BHK": 100.0,
    "2BHK": 200.0,
    "3BHK": 300.0
}

# Special Items
SPECIAL_ITEM_RATE = 50.0 # Per item per labour

# Walking / Distance
WALKING_RATE_PER_50M_PER_LABOUR = 3.0
WALKING_DISTANCE_THRESHOLD = 0 # Prompt doesn't say "First X free". Usually >0 distance implies charge?
# "Distance between pickup and drop location." implies all distance?
# Or usually "Parking to House" distance.
# Prompt item 8: "Distance Charges ... Distance between pickup and drop location."
# This sounds like "Travel Distance"? But usually Labour doesn't travel with goods unless it's a truck.
# Porter context: Distance is usually "Walking distance from truck to house".
# But "Distance between pickup and drop location" implies the TRIP distance?
# Rate: "₹60 per km". This is very expensive for trip distance if typical trip is 10km (600 per labour?).
# Wait. Labourers usually ride with the truck.
# If it is walking distance (head load carrying), then 50m makes sense.
# If it is "Pickup to Drop" (Truck travel), 50m increments is weird.
# Re-reading: "₹3 per 50 meters per labour".
# "Distance between pickup and drop location."
# If I move house A to house B (5km away).
# Labour charge = 5000m / 50 * 3 = 100 * 3 = 300 per labour.
# That seems reasonable for travel time/effort?
# Let's assume input is "Distance in meters".

# Service Type Charge
SERVICE_TYPE_CHARGES = {
    "normal": 0.0,
    "heavy_lifting": 100.0, # Per labour
    "high_risk": 150.0      # Per labour
}

NIGHT_SHIFT_START_HOUR = 22
NIGHT_SHIFT_END_HOUR = 6
NIGHT_SHIFT_SURCHARGE_PERCENT = 0.20 # 20%

GST_PERCENT = 0.0
PLATFORM_FEE_PERCENT = 0.15

# Legacy Heavy Items (Optional, if we still use specific item picker)
# The prompt says: "Special 'Handle With Care' Items ... ₹50 per special item per labour".
# It doesn't explicitly delete the old "Fridge/Sofa" list.
# But "7. Special 'Handle With Care' Items ₹50...".
# Maybe we replace the detailed list with a generic count?
# Or we map the explicit list to "Special Items"?
# "Heavy lifting -> ₹100 per labour" is a Service Type.
# "Special Handle With Care -> ₹50 per item".
# I will keep the detailed list as a UI convenience but maybe classify them as "Special"?
# Or just use a simple counter as requested in prompt "7. Special...".
# User Request says: "7. Special 'Handle With Care' Items ... ₹50 per special item".
# It effectively replaces the old specific price list (80, 70, etc).
# I will Deprecate old map and use generic constant.

class BillingService:
    @staticmethod
    def calculate_estimate(
        labour_count: int,
        floor_no: int,
        lift_available: bool,
        walking_distance_meters: int,
        # New Params
        hours_requested: float = 1.0,
        house_size: str = "1RK",
        special_items_count: int = 0,
        service_charge_type: str = "normal", # normal, heavy_lifting, high_risk
        is_night_shift: bool = False
    ) -> dict:
        """
        Calculates the estimated cost for a job based on new pricing model.
        """
        labour_count = max(1, labour_count)
        hours_requested = max(1.0, hours_requested)
        
        # 1. Base Price (First 1 Hour) = 350 * labour_count
        base_charge = BASE_RATE_PER_LABOUR * labour_count
        
        # 2. Extra Time Charge
        # After 1 hour → ₹50 extra per 30 minutes per labour
        extra_hours = max(0.0, hours_requested - 1.0)
        # Convert to 30 min blocks. 1.5 hrs -> 1 block. 2 hrs -> 2 blocks.
        # math.ceil to safe side? Or proportional? 
        # "₹50 extra per 30 minutes". Usually implies "started 30 min block".
        # 1 hr 1 min -> 1 block? Yes.
        extra_minutes = extra_hours * 60
        time_blocks = math.ceil(extra_minutes / EXTRA_TIME_BLOCK_MINUTES)
        extra_time_charge = time_blocks * EXTRA_TIME_RATE_PER_BLOCK * labour_count
        
        labour_cost_time = base_charge + extra_time_charge
        
        # 3. Floor Charges
        # Lift: 3 per floor/labour. No lift: 10 per floor/labour.
        # "per floor". Ground floor (0) -> 0 charge? 1st floor -> 1 * Rate?
        rate_per_floor = FLOOR_RATE_LIFT if lift_available else FLOOR_RATE_NO_LIFT
        floor_charges = floor_no * rate_per_floor * labour_count
        
        # 4. House Size Charges (Fixed, added once)
        # 1 RK → ₹0, 1 BHK → ₹100, etc.
        house_size_charge = HOUSE_SIZE_CHARGES.get(house_size, 0.0)
        
        # 5. Special Items (Handle With Care)
        # ₹50 per special item (Flat charge, not per labour)
        special_items_charge = special_items_count * SPECIAL_ITEM_RATE
        
        # 6. Distance Charges
        # ₹3 per 50 meters per labour
        # Distance between pickup and drop.
        # units of 50m.
        distance_units = math.ceil(walking_distance_meters / 50.0)
        distance_charge = distance_units * WALKING_RATE_PER_50M_PER_LABOUR * labour_count
        
        # 7. Service Type Charges
        # Normal 0, Heavy 100/labour, High-risk 150/labour
        service_type_rate = SERVICE_TYPE_CHARGES.get(service_charge_type, 0.0)
        service_charge = service_type_rate * labour_count
        
        # Subtotal
        subtotal = (
            labour_cost_time + 
            floor_charges + 
            house_size_charge + 
            special_items_charge + 
            distance_charge + 
            service_charge
        )
        
        # 8. Night Shift Charge
        # If job time is between 10 PM – 6 AM -> Add 20% extra on total amount
        night_shift_surcharge = 0.0
        if is_night_shift:
            night_shift_surcharge = subtotal * NIGHT_SHIFT_SURCHARGE_PERCENT
            
        total_before_gst = subtotal + night_shift_surcharge
        
        # 9. GST (18%)
        gst_amount = total_before_gst * GST_PERCENT
        
        total_estimate = total_before_gst + gst_amount
        
        # Platform Fee & Earning (Estimates)
        # "Deduct platform fee = 15%"
        # Labour earns = (Total - Fee) / Count
        platform_fee = total_estimate * PLATFORM_FEE_PERCENT
        total_labour_pool = total_estimate - platform_fee
        per_labour_earning = total_labour_pool / labour_count
        
        return {
            "base_price": base_charge,
            "labour_cost_time_estimate": extra_time_charge, # Split base/extra? Or sum? Model has labour_cost_time...
            # Model has "base_price" and "labour_cost_time_estimate".
            # Let's map base -> base_price. extra -> labour_cost_time_estimate? 
            # Or make labour_cost_time_estimate stand for "Time based total"? 
            # I will store 'extra_time_charge' in 'labour_cost_time_estimate' for clarity 
            # or sum them. 'base_price' is separate.
            
            "floor_charges_estimate": floor_charges,
            "house_size_charge": house_size_charge,
            "special_items_charge_estimate": special_items_charge,
            "distance_charge_estimate": distance_charge,
            "service_charge_estimate": service_charge,
            
            "night_shift_surcharge": night_shift_surcharge,
            "gst_amount": gst_amount,
            "platform_fee": platform_fee,
            "per_labour_earning": per_labour_earning,
            
            "total_estimated_amount": total_estimate
        }

    @staticmethod
    def calculate_final_bill(
        estimate_data: dict,
        started_at: datetime,
        ended_at: datetime,
        labour_count: int,
        waiting_time_minutes: int = 0
        # We generally use the "Locked" params from estimate (floor, distance, etc.)
        # so we don't need to re-pass them unless they changed. 
        # For this task, we assume only TIME changes.
    ) -> dict:
        """
        Calculates final bill including time overages and waiting time.
        """
        labour_count = max(1, labour_count)
        
        duration_seconds = (ended_at - started_at).total_seconds()
        duration_minutes = math.ceil(duration_seconds / 60)
        
        # 1. Base Charge (from estimate or recalc)
        # We should respect the initial structure.
        # But to be safe, we rebuild the 'Fixed' charges from the estimate data
        # provided we stored them.
        # The estimate_data passed here comes from the DB record.
        
        base_price = estimate_data.get("base_price", 0.0)
        floor_charges = estimate_data.get("floor_charges_estimate", 0.0)
        house_size_charge = estimate_data.get("house_size_charge", 0.0)
        special_items_charge = estimate_data.get("special_items_charge_estimate", 0.0)
        distance_charge = estimate_data.get("distance_charge_estimate", 0.0)
        service_charge = estimate_data.get("service_charge_estimate", 0.0)
        
        # 2. Time Charges (Actual)
        # Base covers first 60 mins
        extra_minutes = max(0, duration_minutes - BASE_TIME_MINUTES)
        time_blocks = math.ceil(extra_minutes / EXTRA_TIME_BLOCK_MINUTES)
        labour_cost_time_final = time_blocks * EXTRA_TIME_RATE_PER_BLOCK * labour_count
        
        # 3. Waiting Charges
        # First 15 minutes free after labour accepts job.
        # "After that -> ₹5 per minute ... Added to total bill"
        waiting_chargeable = max(0, waiting_time_minutes - WAITING_FREE_MINUTES)
        waiting_charges_final = waiting_chargeable * WAITING_RATE_PER_MIN_PER_LABOUR * labour_count # "per labour"?
        # Prompt: "₹350 per labour... Waiting Time Charge ... ₹5 per minute".
        # It doesn't explicitly say "per labour".
        # "Base Labour Charge ... per labour".
        # "Waiting Time Charge ... ₹5 per minute".
        # But usually waiting consumes ALL labours' time.
        # If I have 5 labours waiting, do I pay 5 or 25?
        # Logic says 25 (5 * 5).
        # Let's assume per labour unless specified otherwise, to be fair to labour.
        # "Amount is equally divided among labours". So it must be generated per labour?
        # If 5 rs total, split 5 ways -> 1 rs? Too low.
        # So it is likely ₹5 per minute PER LABOUR.
        # I will use per labour.
        waiting_charges_final = waiting_chargeable * WAITING_RATE_PER_MIN_PER_LABOUR * labour_count 

        # Subtotal
        subtotal = (
            base_price + 
            labour_cost_time_final + 
            floor_charges + 
            house_size_charge + 
            special_items_charge + 
            distance_charge + 
            service_charge + 
            waiting_charges_final
        )
        
        # 4. Night Shift
        # Check if job happened at night?
        # "If job time is between 10 PM – 6 AM".
        # We check `started_at` or `ended_at`.
        # Simple check: If start hour >= 22 or start hour < 6.
        start_hour = started_at.hour
        is_night = start_hour >= NIGHT_SHIFT_START_HOUR or start_hour < NIGHT_SHIFT_END_HOUR
        
        night_shift_surcharge = 0.0
        if is_night:
            night_shift_surcharge = subtotal * NIGHT_SHIFT_SURCHARGE_PERCENT
            
        total_before_gst = subtotal + night_shift_surcharge
        
        # 5. GST
        gst_amount = total_before_gst * GST_PERCENT
        total_final = total_before_gst + gst_amount
        
        # 6. Earning
        platform_fee = total_final * PLATFORM_FEE_PERCENT
        total_labour_pool = total_final - platform_fee
        per_labour_earning = total_labour_pool / labour_count
        
        return {
            "total_final_amount": total_final,
            "labour_cost_time_final": labour_cost_time_final,
            "actual_duration_minutes": duration_minutes,
            
            "waiting_charges_final": waiting_charges_final,
            "floor_charges_final": floor_charges,
            "walking_charges_final": distance_charge, # Using estimate's distance
            
            "service_charge_final": service_charge,
            "special_items_charge_final": special_items_charge,
            "house_size_charge_final": house_size_charge,
            
            "gst_amount_final": gst_amount,
            "platform_fee_final": platform_fee,
            "per_labour_earning_final": per_labour_earning
        }
