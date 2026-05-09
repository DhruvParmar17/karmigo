import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedAddress {
  final String label; // Home, Office, Other
  final String address;
  final double latitude;
  final double longitude;

  SavedAddress({
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
        label: json['label'],
        address: json['address'],
        latitude: json['latitude'],
        longitude: json['longitude'],
      );
}

class SavedAddressService {
  static const String _key = "karmigo_saved_addresses";
  static const int maxAddresses = 3;

  static Future<List<SavedAddress>> getAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => SavedAddress.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> saveAddress(SavedAddress newAddress) async {
    final prefs = await SharedPreferences.getInstance();
    List<SavedAddress> current = await getAddresses();

    // Check if label exists, if so update it
    int index = current.indexWhere((a) => a.label == newAddress.label);
    if (index != -1) {
      current[index] = newAddress;
    } else {
      if (current.length >= maxAddresses) {
        return false; // Limit reached
      }
      current.add(newAddress);
    }

    await prefs.setString(_key, jsonEncode(current.map((e) => e.toJson()).toList()));
    return true;
  }

  static Future<void> deleteAddress(String label) async {
    final prefs = await SharedPreferences.getInstance();
    List<SavedAddress> current = await getAddresses();
    current.removeWhere((a) => a.label == label);
    await prefs.setString(_key, jsonEncode(current.map((e) => e.toJson()).toList()));
  }
}
