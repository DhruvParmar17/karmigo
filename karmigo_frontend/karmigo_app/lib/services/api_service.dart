import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/auth_state.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:8000";
    if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:8000";
    }
    return "http://127.0.0.1:8000";
  }

  // =========================
  // COMMON AUTH HEADER
  // =========================
  static Map<String, String> _headers({bool authRequired = false}) {
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    if (authRequired) {
      if (AuthState.token == null) {
        throw Exception("Authentication required. Please login again.");
      }
      headers["Authorization"] = "Bearer ${AuthState.token}";
    }

    return headers;
  }

  // =========================
  // LOGIN
  // =========================
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: _headers(),
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    print("DEBUG: Login Response -> ${response.body}");
    return _handleResponse(response);
  }

  // =========================
  // SIGNUP
  // =========================
  static Future<Map<String, dynamic>> signup(
      String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/signup"),
      headers: _headers(),
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    return _handleResponse(response);
  }

  // =========================
  // LABOUR OTP AUTH & VERIFICATION
  // =========================
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    // Basic validation
    if (phone.length < 10) throw Exception("Invalid phone number");
    
    final response = await http.post(
      Uri.parse("$baseUrl/auth/labour/send-otp"),
      headers: _headers(),
      body: jsonEncode({"phone": phone}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> loginOtp(String phone, String otp) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/labour/login-otp"),
      headers: _headers(),
      body: jsonEncode({"phone": phone, "otp": otp}),
    );
    return _handleResponse(response);
  }

  static Future<void> submitVerification(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("$baseUrl/labour/verification/submit"),
      headers: _headers(authRequired: true),
      body: jsonEncode(data),
    );
     if (response.statusCode < 200 || response.statusCode >= 300) {
       final data = jsonDecode(response.body);
       throw Exception(data['detail'] ?? "Failed to submit verification");
     }
  }

  static Future<Map<String, dynamic>> getVerificationStatus() async {
    final response = await http.get(
      Uri.parse("$baseUrl/labour/verification/status"),
      headers: _headers(authRequired: true),
    );
    return _handleResponse(response);
  }

  // =========================
  // CUSTOMER OTP AUTH
  // =========================
  static Future<Map<String, dynamic>> sendOtpCustomer(String phone) async {
    if (phone.length < 10) throw Exception("Invalid phone number");
    
    final response = await http.post(
      Uri.parse("$baseUrl/auth/customer/send-otp"),
      headers: _headers(),
      body: jsonEncode({"phone": phone}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> loginOtpCustomer(String phone, String otp) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/customer/login-otp"),
      headers: _headers(),
      body: jsonEncode({"phone": phone, "otp": otp}),
    );
    return _handleResponse(response);
  }

  // =========================
  // CREATE JOB (CUSTOMER)
  // =========================
  static Future<Map<String, dynamic>> createJob({
    required String title,
    required String description,
    required String location,
    double? latitude,
    double? longitude,
  }) async {
    final Map<String, dynamic> body = {
      "title": title,
      "description": description,
      "location": location,
    };
    
    if (latitude != null) body["latitude"] = latitude;
    if (longitude != null) body["longitude"] = longitude;

    // Default fields to match backend schema if needed, though they are optional
    body["work_type"] = title.toLowerCase(); 
    body["labour_count"] = 1; 

    final response = await http.post(
      Uri.parse("$baseUrl/jobs/"),
      headers: _headers(authRequired: true),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // =========================
  // GET MY JOBS (CUSTOMER)
  // =========================
  static Future<List<dynamic>> getMyJobs() async {
    final response = await http.get(
      Uri.parse("$baseUrl/jobs/"),
      headers: _headers(authRequired: true),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? "Failed to load jobs");
    }
  }

  // =========================
  // GET SINGLE JOB (CUSTOMER/LABOUR)
  // =========================
  static Future<Map<String, dynamic>> getJob(String jobId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/jobs/$jobId"),
      headers: _headers(authRequired: true),
    );
     return _handleResponse(response);
  }

  // =========================
  // CUSTOMER PROFILE
  // =========================
  static Future<Map<String, dynamic>> getCustomerMe() async {
    final response = await http.get(
      Uri.parse("$baseUrl/users/me"),
      headers: _headers(authRequired: true),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateCustomerProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse("$baseUrl/users/me"),
      headers: _headers(authRequired: true),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // =========================
  // GET AVAILABLE JOBS (LABOUR)
  // =========================
  // =========================
  // GET JOBS (FILTERABLE)
  // =========================
  static Future<List<dynamic>> getJobs({String? labourId, String? status}) async {
    // Build query parameters
    String query = "$baseUrl/jobs/";
    List<String> params = [];
    if (labourId != null) params.add("labour_id=$labourId");
    if (status != null) params.add("order_status=$status");
    
    if (params.isNotEmpty) {
      query += "?${params.join("&")}";
    }

    final response = await http.get(
      Uri.parse(query),
      headers: _headers(authRequired: true),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? "Failed to load jobs");
    }
  }

  // Wrappers for backward compatibility if needed, using the new general method
  static Future<List<dynamic>> getAvailableJobs() async {
    return getJobs(status: "pending"); // Only show pending jobs in available list
  }


  // =========================
  // ASSIGN JOB TO LABOUR (ACCEPT JOB)
  // =========================
  static Future<void> assignJobToLabour(String jobId) async {
    final response = await http.put(
      Uri.parse("$baseUrl/jobs/$jobId/assign"),
      headers: _headers(authRequired: true),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? "Failed to assign job");
    }
  }

  // =========================
  // UPDATE JOB STATUS
  // =========================
  static Future<void> updateJobStatus({
    required String jobId,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/jobs/$jobId/status?status_value=$status"),
      headers: _headers(authRequired: true),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? "Failed to update job status");
    }
  }

  static Future<void> completeJob(String jobId) async {
    // Reusing updateJobStatus or dedicated endpoint if backend supports
    await updateJobStatus(jobId: jobId, status: "completed");
  }

  static Future<void> cancelJob(String jobId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/jobs/$jobId/cancel"),
      headers: _headers(authRequired: true)
    );
     if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? "Failed to cancel job");
    }
  }

  static Future<void> deleteJob(String jobId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/jobs/$jobId"),
      headers: _headers(authRequired: true)
    );
     if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? "Failed to delete job");
    }
  }

  static Future<Map<String, dynamic>> getWalletBalance() async {
    final response = await http.get(
      Uri.parse("$baseUrl/labour/wallet/balance"),
      headers: _headers(authRequired: true)
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getWalletTransactions() async {
    final response = await http.get(
      Uri.parse("$baseUrl/labour/wallet/transactions"),
      headers: _headers(authRequired: true)
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load transactions");
    }
  }

  // =========================
  // ADMIN API (Using Standards)
  // =========================
  
  static Future<Map<String, dynamic>> getAdminStats() async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/stats"),
      headers: _headers(authRequired: true),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/dashboard"),
      headers: _headers(authRequired: true),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getAdminAlerts() async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/alerts"),
      headers: _headers(authRequired: true),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load alerts");
    }
  }

  static Future<List<dynamic>> getAllJobs({String? status}) async {
    String url = "$baseUrl/admin/jobs";
    if (status != null && status != "All") {
      url += "?status=${status.toLowerCase()}";
    }
    final response = await http.get(
      Uri.parse(url), 
      headers: _headers(authRequired: true),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load jobs");
    }
  }

  static Future<List<dynamic>> getAllUsers() async {
    final response = await http.get(
      Uri.parse("$baseUrl/users/"),
      headers: _headers(authRequired: true),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load users");
    }
  }

  static Future<void> toggleCustomerBlock(String userId, bool block) async {
    final action = block ? 'block' : 'unblock';
    final response = await http.post(
      Uri.parse("$baseUrl/admin/users/$userId/toggle-block?action=$action"),
      headers: _headers(authRequired: true),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Failed to toggle block status");
    }
  }

  static Future<List<dynamic>> getAllLabours() async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/labours"),
      headers: _headers(authRequired: true),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load labours");
    }
  }

  static Future<List<dynamic>> getPendingVerifications() async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/verifications/pending"),
      headers: _headers(authRequired: true),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load pending verifications");
    }
  }

  static Future<void> approveVerification(String labourId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/verifications/$labourId/approve"),
      headers: _headers(authRequired: true),
    );
     if (response.statusCode < 200 || response.statusCode >= 300) {
       throw Exception("Failed to approve verification");
     }
  }

  static Future<void> rejectVerification(String labourId, String reason) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/verifications/$labourId/reject?reason=$reason"),
      headers: _headers(authRequired: true),
    );
     if (response.statusCode < 200 || response.statusCode >= 300) {
       throw Exception("Failed to reject verification");
     }
  }
  
  static Future<void> adminAssignJob(String jobId, String labourId) async {
    // NOTE: This endpoint might assume the current user is a labour.
    // We are required to use this endpoint.
    final response = await http.put(
      Uri.parse("$baseUrl/jobs/$jobId/assign?labour_id=$labourId"),
      headers: _headers(authRequired: true),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? "Failed to assign job");
    }
  }



  // =========================
  // RESPONSE HANDLER
  // =========================
  static dynamic _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'Something went wrong');
    }
  }

  // =========================
  // BILLING API
  // =========================

  static Future<Map<String, dynamic>> getBillingDetails(String jobId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/billing/$jobId"),
      headers: _headers(authRequired: true),
    );
     return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getEstimate(Map<String, dynamic> details) async {
    final response = await http.post(
      Uri.parse("$baseUrl/billing/estimate"),
      headers: _headers(),
      body: jsonEncode(details),
    );
     return _handleResponse(response);
  }

  static Future<void> saveBillingDetails(String jobId, Map<String, dynamic> details) async {
    final response = await http.post(
      Uri.parse("$baseUrl/billing/$jobId/details"),
      headers: _headers(authRequired: true),
      body: jsonEncode(details),
    );
    _handleResponse(response);
  }

  static Future<void> startJobTimer(String jobId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/billing/$jobId/start"),
      headers: _headers(authRequired: true),
    ); 
    _handleResponse(response);
  }

  static Future<Map<String, dynamic>> generateBill(String jobId, {int waitingTimeMinutes = 0}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/billing/$jobId/generate"),
      headers: _headers(authRequired: true),
      body: jsonEncode({
        "waiting_time_minutes": waitingTimeMinutes,
      }),
    );
    return _handleResponse(response);
  }

  static Future<void> payAndCompleteJob(String jobId, {String paymentMethod = "online"}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/billing/$jobId/pay"),
      headers: _headers(authRequired: true),
      body: jsonEncode({
        "payment_method": paymentMethod,
      }),
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
        // Try completing the job
        await updateJobStatus(jobId: jobId, status: "completed");
    } else {
        _handleResponse(response);
    }
  }
  // =========================
  // MAPS PROXY (WEB FIX)
  // =========================
  static Future<List<dynamic>> searchPlaces(String query) async {
      final response = await http.get(Uri.parse("$baseUrl/maps/autocomplete?input=$query"));
      if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'OK') {
              return data['predictions'];
          }
      }
      return [];
  }

  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
       final response = await http.get(Uri.parse("$baseUrl/maps/details?place_id=$placeId"));
       if (response.statusCode == 200) {
           final data = jsonDecode(response.body);
           if (data['status'] == 'OK') {
               return data['result'];
           }
       }
       return null;
  }
  static Future<Map<String, dynamic>> getLabourDetails(String labourId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/labour/$labourId"), 
      headers: _headers(authRequired: true),
    );
     return _handleResponse(response);
  }

  static Future<void> updateLabourProfile(String labourId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse("$baseUrl/labour/$labourId"), 
      headers: _headers(authRequired: true),
      body: jsonEncode(data),
    );
     if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Failed to update labour");
    }
  }

  // =========================
  // LABOUR SPECIFIC NEW APIS
  // =========================
  
  static Future<List<dynamic>> getLaborMyJobs() async {
    final response = await http.get(
      Uri.parse("$baseUrl/labour/jobs/my"),
      headers: _headers(authRequired: true),
    );
    return _handleResponse(response) as List<dynamic>; 
    // Note: If backend returns List directly, handleResponse assumes object.
    // My implementation of _handleResponse assumes key/value or just returns decoded json?
    // line 295: final data = jsonDecode(response.body); return data;
    // If list, data is List. strict type Map<String, dynamic> might fail if List.
  }

  static Future<void> updateLaborJobStatus(String jobId, String status) async {
    final response = await http.post(
      Uri.parse("$baseUrl/labour/jobs/update-status"),
      headers: _headers(authRequired: true),
      body: jsonEncode({
        "job_id": jobId,
        "status": status,
      }),
    );
    _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getJobPaymentDetails(String jobId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/labour/jobs/$jobId/payment"),
      headers: _headers(authRequired: true),
    );
    return _handleResponse(response);
  }
}
