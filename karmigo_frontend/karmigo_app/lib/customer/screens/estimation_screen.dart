
import 'package:flutter/material.dart';
import '../../theme/porter_theme.dart';
import '../../services/api_service.dart';
import 'job_creation/job_creation_state.dart';
import 'searching_labour_screen.dart'; // Will create next

class EstimationScreen extends StatefulWidget {
  final JobCreationState state;

  const EstimationScreen({super.key, required this.state});

  @override
  _EstimationScreenState createState() => _EstimationScreenState();
}

class _EstimationScreenState extends State<EstimationScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _estimate;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEstimate();
  }

  String _mapWorkTypeToBackend(String uiType) {
    uiType = uiType.toLowerCase();
    if (uiType.contains("shifting") || uiType.contains("moving")) return "shifting";
    if (uiType.contains("construction")) return "construction";
    if (uiType.contains("loading") || uiType.contains("unloading")) return "warehouse"; // Fallback for loading to warehouse as per legacy logic
    return "warehouse"; // Default for Others
  }

  void _fetchEstimate() async {
    try {
      final backendWorkType = _mapWorkTypeToBackend(widget.state.workType);
      
      final details = {
        "labour_count": widget.state.labourCount,
        "floor_no": widget.state.floorNo,
        "lift_available": widget.state.liftAvailable,
        "walking_distance_meters": widget.state.walkingDistance,
        "work_type": backendWorkType,
        
        "hours_requested": widget.state.hoursRequested,
        "hours_requested": widget.state.hoursRequested,
        "house_size": (widget.state.workType == "House Shifting") ? (widget.state.houseSize ?? "1RK") : "1RK",
        "special_items_count": widget.state.specialItemsCount,
        "special_items_count": widget.state.specialItemsCount,
        "service_charge_type": widget.state.serviceChargeType ?? "normal",
        "heavy_items": widget.state.heavyItems, // Legacy
      };

      final result = await ApiService.getEstimate(details);
      
      setState(() {
        _estimate = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _confirmBooking() async {
    setState(() => _isLoading = true);
    try {
      // 1. Create Job
      final jobRes = await ApiService.createJob(
        title: widget.state.workType.toUpperCase(),
        description: widget.state.description,
        location: widget.state.address,
        latitude: widget.state.lat,
        longitude: widget.state.lng,
      );
      
      final jobId = jobRes['id']; // Assuming ID is returned
      if (jobId == null) throw Exception("Failed to get Job ID");

      // 2. Save Billing Details
      try {
        final backendWorkType = _mapWorkTypeToBackend(widget.state.workType);

        final billingDetails = {
          "labour_count": widget.state.labourCount,
          "floor_no": widget.state.floorNo,
          "lift_available": widget.state.liftAvailable,
          "walking_distance_meters": widget.state.walkingDistance,
          "work_type": backendWorkType,
          
          "hours_requested": widget.state.hoursRequested,
          "hours_requested": widget.state.hoursRequested,
          "house_size": (widget.state.workType == "House Shifting") ? (widget.state.houseSize ?? "1RK") : "1RK",
          "special_items_count": widget.state.specialItemsCount,
          "special_items_count": widget.state.specialItemsCount,
          "service_charge_type": widget.state.serviceChargeType ?? "normal",
          "heavy_items": widget.state.heavyItems,
        };
        
        await ApiService.saveBillingDetails(jobId, billingDetails);
      } catch (e) {
        print("Billing save failed (non-fatal): $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Using latest estimate (Billing details sync failed)")),
          );
        }
      }

      // 3. Navigate
      if (mounted) {
        Navigator.pushAndRemoveUntil(
           context, 
           MaterialPageRoute(builder: (_) => SearchingLabourScreen(jobId: jobId)),
           (route) => false // Remove back stack to prevent going back to estimate
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Booking Failed: $e")),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Estimate")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("Error: $_error"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildBreakdownCard(),
                      const SizedBox(height: 20),
                      Text(
                         "Note: Final price might vary based on actual time taken and additional requirements.",
                         style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               if (_estimate != null)
                 Padding(
                   padding: const EdgeInsets.only(bottom: 8.0),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text("Total Estimate", style: TextStyle(fontWeight: FontWeight.bold)),
                       Text(
                         "₹${_estimate!['total_estimated_amount']}", 
                         style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: PorterTheme.primaryColor)
                       ),
                     ],
                   ),
                 ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoading || _estimate == null) ? null : _confirmBooking,
                  child: const Text("Confirm & Book"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PorterTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PorterTheme.primaryColor),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: PorterTheme.primaryColor),
          SizedBox(width: 10),
          Text(
            "Starting from ₹350", 
            style: TextStyle(fontWeight: FontWeight.bold, color: PorterTheme.primaryColor)
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard() {
    if (_estimate == null) return const SizedBox();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Fare Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _row("Base Fare (1st Hour)", _estimate!['base_price']),
            
            // Time Charges
            if ((_estimate!['labour_cost_time_estimate'] as num) > 0)
               _row("Extra Time Charges", _estimate!['labour_cost_time_estimate']),
               
            // House Size
            if ((_estimate!['house_size_charge'] as num) > 0)
               _row("House Size Charge", _estimate!['house_size_charge']),
               
            // Special Items
            if ((_estimate!['special_items_charge_estimate'] as num) > 0)
               _row("Item Handling Charges", _estimate!['special_items_charge_estimate']),
               
            // Floor
            if ((_estimate!['floor_charges_estimate'] as num) > 0)
              _row("Floor Charges", _estimate!['floor_charges_estimate']),
              
            // Distance
            if ((_estimate!['distance_charge_estimate'] ?? _estimate!['walking_charges_estimate'] ?? 0) > 0)
              _row("Walking Distance", _estimate!['distance_charge_estimate'] ?? _estimate!['walking_charges_estimate']),
              
            // GST
            if ((_estimate!['gst_amount'] as num) > 0)
              _row("GST (18%)", _estimate!['gst_amount']),
            const Divider(),
            _row("Estimated Total", _estimate!['total_estimated_amount'], isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, dynamic amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text("₹$amount", style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
