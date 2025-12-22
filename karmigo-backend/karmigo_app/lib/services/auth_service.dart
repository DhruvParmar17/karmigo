import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/login_request.dart';

class LoginResult {
  final String accessToken;
  final String role;

  LoginResult({required this.accessToken, required this.role});
}

class AuthService {
  AuthService._internal();

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  static const String _baseUrl = 'http://localhost:8000';
  static const String _tokenKey = 'karmigo_token';
  static const String _roleKey = 'karmigo_role';

  Future<LoginResult> login(LoginRequest request) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Login failed (${response.statusCode})');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final token = data['access_token'] ?? data['token'];
    if (token == null || token.isEmpty) {
      throw Exception('Token missing in response');
    }

    // Best-effort role detection from payload keys the backend may return.
    final role = (data['role'] ??
            data['user_role'] ??
            (data['is_superuser'] == true ? 'admin' : null) ??
            'customer')
        .toString();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, role);

    return LoginResult(accessToken: token, role: role);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    if (token == null) return {};
    return {'Authorization': 'Bearer $token'};
  }
}

