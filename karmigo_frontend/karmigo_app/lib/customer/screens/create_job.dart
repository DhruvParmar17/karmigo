import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/porter_theme.dart';
import 'customer_main_screen.dart';
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CreateJobScreen extends StatefulWidget {
  final String? initialWorkType;
  final Map<String, dynamic>? prefillData; // New argument for Re-Book

  const CreateJobScreen({super.key, this.initialWorkType, this.prefillData});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _workType;
  final TextEditingController _locationController = TextEditingController();
  double? _latitude;
  double? _longitude;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _numLabours = "1";
  bool _isLoading = false;

  // Billing Fields
  int _floorNo = 0;
  bool _liftAvailable = true;
  int _walkingDistance = 0;
  double _estimatedPrice = 0.0;
  Timer? _debounce;
  
  // New Fields
  double _hoursRequested = 1.0;
  String _houseSize = "1RK"; // 1RK, 1BHK, 2BHK, 3BHK
  int _specialItemsCount = 0;

  // Book for someone else
  bool _bookForSomeoneElse = false;
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController = TextEditingController();
  final TextEditingController _receiverAddressController = TextEditingController();

  // Heavy Items Counter (Legacy / UI helper)
  // We can let user pick specific items and sum them up to specialItemsCount
  // OR just use a simple counter as requested.
  // Prompt: "7. Special 'Handle With Care' Items ... ₹50 per special item"
  // I will hide the complex list and replace with a simple counter.
  // Or Keep complex list but count total items as special items?
  // "Heavy lifting -> ₹100 per labour" is Service Type.
  // I will replace the detailed list with a simple "Special Items" counter to match the new simplified requirement "₹50 per special item".
  // The old list had varying prices (80, 70, etc). The new req is flat 50.
  // So I will remove the old map and add a simple int counter.


  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location permission denied")));
           return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location permission denied forever")));
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _latitude = position.latitude;
      _longitude = position.longitude;
      
      // Get Address
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.street}, ${place.subLocality}, ${place.locality} - ${place.postalCode}";
        _locationController.text = address;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error getting location: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final List<String> _workTypes = [
    "Shifting",
    "Loading",
    "Unloading",
    "Stair Climbing",
    "Construction Work",
    "Heavy Item Shifting",
    "Warehouse Loading",
    "Office Shifting",
    "Furniture Moving",
    "Event Setup Labour",
    "Other"
  ];

  final List<String> _labourCounts = [
    "1", "2", "3", "4", "5", "6", "10+"
  ];

  @override
  void initState() {
    super.initState();
    
    // Default or Prefill
    if (widget.prefillData != null) {
       final data = widget.prefillData!;
       _workType = data['work_type_ui'] ?? widget.initialWorkType ?? _workTypes.first;
       _descriptionController.text = data['description'] ?? "";
       _locationController.text = data['location'] ?? "";
       _latitude = data['latitude'];
       _longitude = data['longitude'];
       _numLabours = (data['labour_count'] ?? 1).toString();
       
       // Optional details if available
       _floorNo = data['floor_no'] ?? 0;
       _liftAvailable = data['lift_available'] ?? true;
       _walkingDistance = data['walking_distance'] ?? 0;
       
       // Handle simplified Work Type selection if strictly required, 
       // but _workType above tries to match UI string.
       // Only if provided string exists in _workTypes
       if (!_workTypes.contains(_workType)) {
          // Try to fallback or find closest match?
          // For now, if exact match fails, default to first.
           _workType = _workTypes.first;
       }

    } else {
       _workType = widget.initialWorkType ?? _workTypes.first;
       // Only auto-detect location if NOT re-booking (unless re-book has no location)
       if (_latitude == null) _getCurrentLocation();
    }
    
    _calculateEstimate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  String _mapWorkTypeToBackend(String uiType) {
    uiType = uiType.toLowerCase();
    if (uiType.contains("shifting") || uiType.contains("moving")) return "shifting";
    if (uiType.contains("construction")) return "construction";
    if (uiType.contains("other")) return "other_general";
    return "warehouse";
  }

  void _calculateEstimate() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final backendType = _mapWorkTypeToBackend(_workType);
        
        // Map Work Type to Service Charge Type
        // "Heavy lifting → ₹100 per labour", "High-risk work → ₹150 per labour"
        // UI has "Heavy Item Shifting" -> maybe heavy_lifting
        // "Construction Work" -> maybe heavy?
        // Let's implement a mapping helper or simple logic.
        String serviceChargeType = "normal";
        if (_workType.contains("Heavy")) serviceChargeType = "heavy_lifting";
        if (_workType.contains("Construction")) serviceChargeType = "heavy_lifting";
        // if user selects "Glass" or something -> High Risk?
        // For now: 
        if (_workType == "Heavy Item Shifting") serviceChargeType = "heavy_lifting";
        // Prompt says "high-risk work". I don't see that in UI list. I'll stick to normal/heavy.

        final details = {
          "work_type": backendType,
          "labour_count": int.tryParse(_numLabours) ?? 1,
          "floor_no": _floorNo,
          "lift_available": _liftAvailable,
          "walking_distance_meters": _walkingDistance,
          
          // New Inputs
          "hours_requested": _hoursRequested,
          "house_size": (_workType == "Shifting") ? _houseSize : null,
          "special_items_count": _specialItemsCount,
          "service_charge_type": serviceChargeType,
          
          // Legacy (send empty if backend expects dict, but we made it optional on backend or handled string)
          "heavy_items": {}, 
        };

        final res = await ApiService.getEstimate(details);
        if (mounted) {
          setState(() {
            _estimatedPrice = (res['total_estimated_amount'] as num).toDouble();
            // We can also show breakdown if we want, checking res.
          });
        }
      } catch (e) {
        print("Estimate Error: $e");
      }
    });
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String packedDescription = 
          "Work: ${_descriptionController.text.trim()}\n"
          "Labours Required: $_numLabours\n"
          "Notes: ${_notesController.text.trim()}";

      if (_bookForSomeoneElse) {
         packedDescription += "\n\n--- BOOKED FOR SOMEONE ELSE ---\n"
             "Receiver Name: ${_receiverNameController.text.trim()}\n"
             "Receiver Phone: ${_receiverPhoneController.text.trim()}\n"
             "Receiver Address: ${_receiverAddressController.text.trim()}";
      }

      // 1. Create Job (Order)
      final job = await ApiService.createJob(
        title: _workType,
        description: packedDescription,
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      // 2. Save Billing Details
      final jobId = job['id'];
      final backendType = _mapWorkTypeToBackend(_workType);
      
      // Determine Service Charge Type again
      String serviceChargeType = "normal";
      if (_workType.contains("Heavy")) serviceChargeType = "heavy_lifting";
      if (_workType == "Heavy Item Shifting") serviceChargeType = "heavy_lifting";

      await ApiService.saveBillingDetails(jobId, {
        "work_type": backendType,
        "labour_count": int.tryParse(_numLabours) ?? 1,
        "floor_no": _floorNo,
        "lift_available": _liftAvailable,
        "walking_distance_meters": _walkingDistance,
        
        "hours_requested": _hoursRequested,
        "house_size": (_workType == "Shifting") ? _houseSize : null,
        "special_items_count": _specialItemsCount,
        "service_charge_type": serviceChargeType,
        
        // Legacy
        "heavy_items": {},
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Job created successfully!")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
        (route) => false,
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCounter(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Row(
            children: [
               IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  if (value > 0) onChanged(value - 1);
                },
              ),
              Text("$value", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  onChanged(value + 1);
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Job & Estimate")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ESTIMATE CARD
              Card(
                color: PorterTheme.primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      const Text("Estimated Price", style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 5),
                      Text("₹${_estimatedPrice.toStringAsFixed(0)}", 
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: PorterTheme.primaryColor)),
                      const Text("*Includes GST & Base Charges", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // NUMBER OF LABOURS (Moved Up)
              DropdownButtonFormField<String>(
                value: _numLabours,
                items: _labourCounts.map((num) => DropdownMenuItem(value: num, child: Text("$num Labour(s)"))).toList(),
                onChanged: (val) {
                   setState(() => _numLabours = val!);
                   _calculateEstimate();
                },
                decoration: const InputDecoration(labelText: "Labours Required", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              // WORK TYPE
              const Text("Work Type", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _workTypes.contains(_workType) ? _workType : _workTypes.first,
                items: _workTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  setState(() => _workType = val!);
                  _calculateEstimate();
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              
              // HOURS REQUESTED
              Text("Time Required: ${_hoursRequested.toStringAsFixed(1)} Hours", style: const TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _hoursRequested,
                min: 1.0,
                max: 12.0,
                divisions: 22, // 0.5 steps
                label: "${_hoursRequested} hrs",
                onChanged: (val) {
                  setState(() => _hoursRequested = val);
                  _calculateEstimate();
                },
              ),

              // DESCRIPTION
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Work Description",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              
              // DETAILS (Floor, Lift, etc)
              const Text("Job Details", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              // HOUSE SIZE
              // HOUSE SIZE - ONLY FOR SHIFTING
              if (_workType == "Shifting") ...[
                DropdownButtonFormField<String>(
                  value: _houseSize,
                  items: ["1RK", "1BHK", "2BHK", "3BHK"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                     setState(() => _houseSize = val!);
                     _calculateEstimate();
                  },
                  decoration: const InputDecoration(labelText: "House Size", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: "Floor No."),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setState(() => _floorNo = int.tryParse(val) ?? 0);
                        _calculateEstimate();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text("Lift?"),
                      value: _liftAvailable,
                      onChanged: (val) {
                         setState(() => _liftAvailable = val!);
                         _calculateEstimate();
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Walking Distance (meters)"),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  setState(() => _walkingDistance = int.tryParse(val) ?? 0);
                  _calculateEstimate();
                },
              ),
              const SizedBox(height: 10),
              
              // SPECIAL ITEMS
              _buildCounter("Special / Fragile Items (₹50/ea)", _specialItemsCount, (val) {
                 setState(() => _specialItemsCount = val);
                 _calculateEstimate();
              }),
              
              const SizedBox(height: 20),
              // REMOVED OLD HEAVY ITEMS LIST
              const SizedBox(height: 20),

              // LOCATION
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: "Location",
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location, color: PorterTheme.primaryColor),
                    onPressed: _getCurrentLocation,
                    tooltip: "Use Current Location",
                  ),
                  border: const OutlineInputBorder(),
                  helperText: "Type or use GPS button",
                ),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),

              // BOOK FOR SOMEONE ELSE
              CheckboxListTile(
                title: const Text("Book for someone else?", style: TextStyle(fontWeight: FontWeight.bold)),
                value: _bookForSomeoneElse,
                onChanged: (val) => setState(() => _bookForSomeoneElse = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              if (_bookForSomeoneElse) ...[
                 TextFormField(
                   controller: _receiverNameController,
                   decoration: const InputDecoration(labelText: "Receiver Name*", border: OutlineInputBorder()),
                   validator: (val) => _bookForSomeoneElse && (val == null || val.isEmpty) ? "Required" : null,
                 ),
                 const SizedBox(height: 10),
                 TextFormField(
                   controller: _receiverPhoneController,
                   keyboardType: TextInputType.phone,
                   decoration: const InputDecoration(labelText: "Receiver Phone*", border: OutlineInputBorder()),
                   validator: (val) => _bookForSomeoneElse && (val == null || val.isEmpty) ? "Required" : null,
                 ),
                 const SizedBox(height: 10),
                 TextFormField(
                   controller: _receiverAddressController,
                   decoration: const InputDecoration(labelText: "Receiver Address (Drop/Job Location)*", border: OutlineInputBorder()),
                   validator: (val) => _bookForSomeoneElse && (val == null || val.isEmpty) ? "Required" : null,
                   maxLines: 2,
                 ),
              ],

              const SizedBox(height: 30),

              // SUBMIT BUTTON
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PorterTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Book Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
