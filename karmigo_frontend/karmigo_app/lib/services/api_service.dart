import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/auth_state.dart';

class ApiService {
  static const String baseUrl = "http://localhost:8000";

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
  // CREATE JOB (CUSTOMER)
  // =========================
  static Future<Map<String, dynamic>> createJob({
    required String title,
    required String description,
    required String location,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/jobs/"),
      headers: _headers(authRequired: true),
      body: jsonEncode({
        "title": title,
        "description": description,
        "location": location,
      }),
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
  // GET AVAILABLE JOBS (LABOUR)
  // =========================
  static Future<List<dynamic>> getAvailableJobs() async {
    final response = await http.get(
      Uri.parse("$baseUrl/jobs/"),
      headers: _headers(authRequired: true),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? "Failed to load available jobs");
    }
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
      Uri.parse("$baseUrl/jobs/$jobId/status"),
      headers: _headers(authRequired: true),
      body: jsonEncode({
        "status": status,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? "Failed to update job status");
    }
  }

  // =========================
  // RESPONSE HANDLER
  // =========================
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'Something went wrong');
    }
  }
}
