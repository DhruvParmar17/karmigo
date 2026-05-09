import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import '../../../theme/porter_theme.dart';
import 'job_creation_state.dart';
import '../estimation_screen.dart';
import '../../../services/api_service.dart';
import '../../../services/saved_address_service.dart';

class Step5LocationScreen extends StatefulWidget {
  final JobCreationState state;

  const Step5LocationScreen({super.key, required this.state});

  @override
  _Step5LocationScreenState createState() => _Step5LocationScreenState();
}

class _Step5LocationScreenState extends State<Step5LocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _confirmedAddressController = TextEditingController(); // For manual edit
  final MapController _mapController = MapController();
  
  // State
  List<dynamic> _placePredictions = [];
  bool _isLoading = false;
  bool _isMapMoving = false;
  bool _isManuallyEdited = false; // Flag to track manual edits
  LatLng _currentCenter = const LatLng(19.0760, 72.8777); // Default Mumbai
  Timer? _debounce;
  List<SavedAddress> _savedAddresses = []; // Saved addresses
  
  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
    // Initialize with state if available
    if (widget.state.lat != null && widget.state.lng != null) {
      _currentCenter = LatLng(widget.state.lat!, widget.state.lng!);
      _searchController.text = widget.state.address;
      _confirmedAddressController.text = widget.state.address;
    } else {
        // Auto-detect location on start
        _getCurrentLocation();
    }
  }

  Future<void> _loadSavedAddresses() async {
    final list = await SavedAddressService.getAddresses();
    if (mounted) setState(() => _savedAddresses = list);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _confirmedAddressController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ---------------------------------------------
  // 1. GET CURRENT LOCATION (GPS)
  // ---------------------------------------------
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location services are disabled")));
        return;
      }

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

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      _moveToLocation(position.latitude, position.longitude);
      
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _moveToLocation(double lat, double lng) {
    final pos = LatLng(lat, lng);
    _mapController.move(pos, 16.5); 
    _onMapMoveEnd(pos); 
  }

  // ---------------------------------------------
  // 2. REVERSE GEOCODING (ON MAP MOVE)
  // ---------------------------------------------
  void _onMapMoveEnd(LatLng center) { 
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () async {
          if (!mounted) return;
          
          setState(() {
             _currentCenter = center;
             _isLoading = true;
          });

          try {
             List<Placemark> placemarks = await placemarkFromCoordinates(center.latitude, center.longitude);
             if (placemarks.isNotEmpty) {
               final p = placemarks.first;
               // Format: Street, SubLocality, Locality, PostalCode
               final components = [
                 p.street,
                 p.subLocality,
                 p.locality,
                 p.postalCode
               ].where((element) => element != null && element.isNotEmpty).toSet().toList(); 
               
               final fullAddress = components.join(", ");
               
              
               if (mounted) {
                 setState(() {
                   // Only update if user hasn't manually edited
                   if (!_isManuallyEdited) {
                      _confirmedAddressController.text = fullAddress;
                   }
                 });
               }
             }
          } catch (e) {
             print("Geocoding Error: $e");
          } finally {
             if (mounted) setState(() => _isLoading = false);
          }
      });
  }

  // ---------------------------------------------
  // 3. AUTOCOMPLETE SEARCH
  // ---------------------------------------------
  Future<void> _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() => _placePredictions = []);
      return;
    }
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
        try {
          final predictions = await ApiService.searchPlaces(value);
          if (mounted) {
            setState(() {
              _placePredictions = predictions;
            });
          }
        } catch (e) {
          print("Places Error: $e");
        }
    });
  }

  Future<void> _selectPlace(dynamic place) async {
    final placeId = place['place_id'];
    final description = place['description'];
    
    // Clear predictions immediately
    setState(() {
        _searchController.text = description;
        _placePredictions = []; 
        _isLoading = true;
        _isManuallyEdited = false; // Reset manual edit since we selected a new place
    });

    try {
      final details = await ApiService.getPlaceDetails(placeId);
      
      if (details != null) {
          final loc = details['geometry']['location'];
          final lat = loc['lat'];
          final lng = loc['lng'];
          
          _moveToLocation(lat, lng);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to fetch location details")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------
  // 4. CONFIRM & PROCEED
  // ---------------------------------------------
  void _confirmLocation() {
    final finalAddress = _confirmedAddressController.text.trim();
    
    if (finalAddress.isEmpty || finalAddress.contains("Move map")) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter or select a valid address")));
        return;
    }
    
    // Update State
    widget.state.updateLocation(finalAddress, _currentCenter.latitude, _currentCenter.longitude);
    
    // Navigate
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstimationScreen(state: widget.state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --------------------------
          // 1. FULL SCREEN MAP
          // --------------------------
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 16.0,
              onMapEvent: (evt) {
                 if (evt is MapEventMoveStart) {
                    setState(() => _isMapMoving = true);
                 } else if (evt is MapEventMoveEnd) {
                    setState(() => _isMapMoving = false);
                    _onMapMoveEnd(evt.camera.center);
                 }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.karmigo.app', 
              ),
            ],
          ),

          // --------------------------
          // 2. CENTER PIN
          // --------------------------
           IgnorePointer(
            child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -25), 
                  child: const Icon(Icons.location_on, size: 50, color: Colors.red),
                ),
            ),
          ),
          IgnorePointer(
               child: Center(
                 child: Container(
                   margin: const EdgeInsets.only(top: 25), 
                   width: 10, height: 4,
                   decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(5)
                   ),
                ),
              ),
          ),

          // --------------------------
          // 3. TOP SEARCH BAR
          // --------------------------
          SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
                    ]
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Search for a building, street...",
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty 
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: () { 
                               _searchController.clear(); 
                               _onSearchChanged(""); 
                            }) 
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                
                // PREDICTIONS LIST
                if (_placePredictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _placePredictions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                         final place = _placePredictions[i];
                         return ListTile(
                            leading: const Icon(Icons.location_on_outlined, color: Colors.grey),
                            title: Text(place['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                            onTap: () => _selectPlace(place),
                         );
                      },
                    ),
                  )
              ],
            ),
          ),
          
          // --------------------------
          // 4. CURRENT LOCATION BTN
          // --------------------------
          Positioned(
            right: 16,
            bottom: 240, // Shifted up slightly
            child: FloatingActionButton(
               backgroundColor: Colors.white,
               child: const Icon(Icons.my_location, color: PorterTheme.primaryColor),
               onPressed: _getCurrentLocation,
            ),
          ),

          // --------------------------
          // 5. BOTTOM CONFIRM SHEET
          // --------------------------
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                     children: [
                        const Text("Select Location", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (_savedAddresses.isNotEmpty)
                           const Icon(Icons.star, color: Colors.amber, size: 14),
                     ],
                   ),
                   const SizedBox(height: 10),
                   
                   // Saved Addresses Chips
                   if (_savedAddresses.isNotEmpty) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _savedAddresses.map((addr) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ActionChip(
                                avatar: Icon(
                                  addr.label == "Home" ? Icons.home : 
                                  addr.label == "Office" ? Icons.work : Icons.location_on,
                                  size: 16,
                                  color: PorterTheme.primaryColor
                                ),
                                label: Text(addr.label),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: PorterTheme.primaryColor),
                                onPressed: () {
                                  // 1. Move map
                                  final pos = LatLng(addr.latitude, addr.longitude);
                                  _mapController.move(pos, 16.5);
                                  
                                  // 2. Update text and internal state
                                  setState(() {
                                    _currentCenter = pos;
                                    _confirmedAddressController.text = addr.address;
                                    _isManuallyEdited = true; // IMPORTANT: Prevent reverse geocoding from overwriting
                                  });
                                  
                                  // 3. User still needs to press "Confirm Location"
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                   ],

                   Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Icon(Icons.location_on, color: PorterTheme.primaryColor, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                           child: TextField(
                             controller: _confirmedAddressController,
                             maxLines: 2,
                             onChanged: (val) {
                               // Mark as manually edited so map doesn't overwrite it
                               if (!_isManuallyEdited && val.isNotEmpty) {
                                  setState(() => _isManuallyEdited = true);
                               }
                             },
                             decoration: InputDecoration(
                               hintText: "Enter full address / Flat No / Landmark",
                               border: const OutlineInputBorder(),
                               contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                               suffixIcon: _isManuallyEdited 
                                  ? IconButton(
                                      icon: const Icon(Icons.refresh, color: Colors.blue),
                                      tooltip: "Reset to Map Location",
                                      onPressed: () {
                                         // Force trigger map move end to re-fetch location
                                         setState(() => _isManuallyEdited = false);
                                         _onMapMoveEnd(_currentCenter);
                                      },
                                    )
                                  : null
                             ),
                           ),
                        ),
                     ],
                   ),
                   const SizedBox(height: 20),
                   
                   ElevatedButton(
                     onPressed: _isLoading ? null : _confirmLocation,
                     style: ElevatedButton.styleFrom(
                        backgroundColor: PorterTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                     ),
                     child: const Text("Confirm Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
