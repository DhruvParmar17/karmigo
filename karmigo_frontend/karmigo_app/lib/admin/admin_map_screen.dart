
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/api_service.dart';
import '../../theme/porter_theme.dart';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  bool _isLoading = true;

  // Default: Mumbai
  static const LatLng _initialPos = LatLng(19.0760, 72.8777);

  @override
  void initState() {
    super.initState();
    _loadJobConfig();
  }

  Future<void> _loadJobConfig() async {
    try {
      final jobs = await ApiService.getAllJobs();
      final markers = <Marker>[];

      for (var job in jobs) {
        final double? lat = job['latitude'];
        final double? lng = job['longitude'];
        final String title = job['title'] ?? 'Job';
        final String status = job['order_status'] ?? 'pending';
        final String jobId = job['id'].toString();

        if (lat != null && lng != null && lat != 0 && lng != 0) {
          Color color = Colors.red; // Pending
          if (status == 'assigned') color = Colors.blue;
          if (status == 'completed') color = Colors.green;

          markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(title),
                      content: Text("Status: $status"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Close")
                        )
                      ],
                    )
                  );
                },
                child: Icon(Icons.location_on, color: color, size: 40),
              ),
            ),
          );
        }
      }

      setState(() {
        _markers = markers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading map: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Job Map")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialPos,
                initialZoom: 11.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.yourcompany.karmigo.karmigo_app',
                ),
                MarkerLayer(
                  markers: _markers,
                ),
              ],
            ),
    );
  }
}
