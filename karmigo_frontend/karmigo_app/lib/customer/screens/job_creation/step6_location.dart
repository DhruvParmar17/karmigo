import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../theme/porter_theme.dart';
import 'job_creation_state.dart';
import '../estimation_screen.dart';

class Step6LocationScreen extends StatefulWidget {
  final JobCreationState state;

  const Step6LocationScreen({super.key, required this.state});

  @override
  _Step6LocationScreenState createState() => _Step6LocationScreenState();
}

class _Step6LocationScreenState extends State<Step6LocationScreen> {
  final TextEditingController _addressController = TextEditingController();
  List<dynamic> _placePredictions = [];
  bool _isLoading = false;

  // ⚠️ REPLACE WITH YOUR REAL API KEY
  static const String _googleApiKey = "AIzaSyDP1h7xxjpi8vajKUIksfEVaDAiY7_GCuM";

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.state.address;
  }

  void _next() {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter address")),
      );
      return;
    }
    
    // Fallback if not set via API/GPS
    if (widget.state.lat == null) {
       widget.state.updateLocation(_addressController.text, 0.0, 0.0);
    } else {
       if (widget.state.address != _addressController.text) {
          widget.state.updateLocation(_addressController.text, widget.state.lat!, widget.state.lng!);
       }
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstimationScreen(state: widget.state),
      ),
    );
  }

  // ---------------------------------------------
  // 1. GET CURRENT LOCATION (GPS)
  // ---------------------------------------------
  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw "Location services are disabled.";
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw "Location permissions are denied";
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw "Location permissions are permanently denied.";
      }

      final position = await Geolocator.getCurrentPosition();
      
      // Reverse Geocode
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final fullAddress = "${p.street}, ${p.subLocality}, ${p.locality}, ${p.postalCode}";
        
        setState(() {
          _addressController.text = fullAddress;
          _placePredictions = []; 
        });
        
        widget.state.updateLocation(fullAddress, position.latitude, position.longitude);
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------
  // 2. GOOGLE PLACES AUTOCOMPLETE
  // ---------------------------------------------
  Future<void> _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() => _placePredictions = []);
      return;
    }
    
    final url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$value&key=$_googleApiKey";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _placePredictions = data['predictions'];
          });
        }
      }
    } catch (e) {
      print("Places Error: $e");
    }
  }

  Future<void> _selectPlace(dynamic place) async {
    final placeId = place['place_id'];
    final description = place['description'];
    
    // Get Details (Lat/Lng)
    final url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey";
    
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final loc = data['result']['geometry']['location'];
          final lat = loc['lat'];
          final lng = loc['lng'];
          
          setState(() {
            _addressController.text = description;
            _placePredictions = [];
          });
          
          widget.state.updateLocation(description, lat, lng);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to fetch location details")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Where do you need the service?",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            
            // Search Bar
            TextField(
              controller: _addressController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Enter full address",
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: _isLoading 
                  ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _useCurrentLocation,
                  ),
                border: const OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Current Location Button
            TextButton.icon(
              onPressed: _useCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text("Use my current location"),
            ),
            
            const Divider(),
            
            // Suggestions List
            if (_placePredictions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _placePredictions.length,
                  itemBuilder: (context, index) {
                    final place = _placePredictions[index];
                    return ListTile(
                      leading: const Icon(Icons.place, color: Colors.grey),
                      title: Text(place['description']),
                      onTap: () => _selectPlace(place),
                    );
                  },
                ),
              )
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _next,
            child: const Text("Get Estimate"),
          ),
        ),
      ),
    );
  }
}
