
import 'package:flutter/material.dart';

class JobCreationState extends ChangeNotifier {
  String workType = "shifting";
  String description = "";
  int labourCount = 1;
  
  // Details
  Set<String> selectedSubOptions = {};

  int floorNo = 0;
  bool liftAvailable = true;
  int walkingDistance = 0;
  
  // New Pricing Fields
  double hoursRequested = 1.0;
  String houseSize = "1RK";
  int specialItemsCount = 0;
  String serviceChargeType = "normal";
  
  // Legacy (keep for now or remove if unused in Step5)
  Map<String, int> heavyItems = {};
  
  // Location
  String address = "";
  double? lat;
  double? lng;
  
  void updateWorkType(String value) {
    if (workType != value) {
        workType = value;
        selectedSubOptions.clear(); // Reset sub-options on category change
    }
    notifyListeners();
  }
  
  void toggleSubOption(String option) {
    if (selectedSubOptions.contains(option)) {
      selectedSubOptions.remove(option);
    } else {
      selectedSubOptions.add(option);
    }
    notifyListeners();
  }

  void updateDescription(String value) {
    description = value;
    notifyListeners();
  }
  
  void updateLabourCount(int value) {
    labourCount = value;
    notifyListeners();
  }
  
  void updateDetails({
    int? floor, 
    bool? lift, 
    int? distance,
    double? hours,
    String? size,
    int? specialItems,
    String? serviceType
  }) {
    if (floor != null) floorNo = floor;
    if (lift != null) liftAvailable = lift;
    if (distance != null) walkingDistance = distance;
    
    if (hours != null) hoursRequested = hours;
    if (size != null) houseSize = size;
    if (specialItems != null) specialItemsCount = specialItems;
    if (serviceType != null) serviceChargeType = serviceType;
    
    notifyListeners();
  }
  
  void addHeavyItem(String key) {
    heavyItems[key] = (heavyItems[key] ?? 0) + 1;
    notifyListeners();
  }
  
  void removeHeavyItem(String key) {
    if ((heavyItems[key] ?? 0) > 0) {
      heavyItems[key] = (heavyItems[key]! - 1);
      if (heavyItems[key] == 0) heavyItems.remove(key);
      notifyListeners();
    }
  }
  
  void updateLocation(String addr, double latitude, double longitude) {
    address = addr;
    lat = latitude;
    lng = longitude;
    notifyListeners();
  }
}
