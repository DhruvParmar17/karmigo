import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/labour.dart';
import '../models/order.dart';
import '../models/user.dart';
import 'auth_service.dart';

class ApiService {
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static const String _baseUrl = 'http://localhost:8000';
  final AuthService _authService = AuthService();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: query);
  }

  Future<http.Response> _get(String path, {Map<String, dynamic>? query}) async {
    final headers = await _authService.authHeaders();
    return http.get(_uri(path, query), headers: headers);
  }

  Future<http.Response> _post(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      ...await _authService.authHeaders(),
    };
    return http.post(_uri(path, query), headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> _put(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      ...await _authService.authHeaders(),
    };
    return http.put(_uri(path, query), headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> _delete(String path) async {
    final headers = await _authService.authHeaders();
    return http.delete(_uri(path), headers: headers);
  }

  // Users
  Future<List<User>> listUsers({int limit = 50}) async {
    final res = await _get('/users/', query: {'limit': '$limit'});
    _throwIfFailed(res);
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => User.fromJson(e)).toList();
  }

  Future<User> createUser(User user) async {
    final res = await _post('/users/', body: user.toJson());
    _throwIfFailed(res);
    return User.fromJson(jsonDecode(res.body));
  }

  Future<User> getUser(String userId) async {
    final res = await _get('/users/$userId');
    _throwIfFailed(res);
    return User.fromJson(jsonDecode(res.body));
  }

  Future<void> deleteUser(String userId) async {
    final res = await _delete('/users/$userId');
    _throwIfFailed(res, allowNoContent: true);
  }

  // Jobs
  Future<List<Order>> listJobs({int limit = 50}) async {
    final res = await _get('/jobs/', query: {'limit': '$limit'});
    _throwIfFailed(res);
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Order.fromJson(e)).toList();
  }

  Future<Order> createJob(Order order) async {
    final res = await _post('/jobs/', body: order.toJson());
    _throwIfFailed(res);
    return Order.fromJson(jsonDecode(res.body));
  }

  Future<Order> getJob(String jobId) async {
    final res = await _get('/jobs/$jobId');
    _throwIfFailed(res);
    return Order.fromJson(jsonDecode(res.body));
  }

  Future<Order> updateJobStatus(String jobId, String statusValue) async {
    final res = await _put(
      '/jobs/$jobId/status',
      query: {'status_value': statusValue},
    );
    _throwIfFailed(res);
    return Order.fromJson(jsonDecode(res.body));
  }

  Future<Order> assignLabour(String jobId, String labourId) async {
    final res = await _put(
      '/jobs/$jobId/assign',
      query: {'labour_id': labourId},
    );
    _throwIfFailed(res);
    return Order.fromJson(jsonDecode(res.body));
  }

  // Labour
  Future<Labour> addLabour(Labour labour) async {
    final res = await _post('/labour/add', body: labour.toJson());
    _throwIfFailed(res);
    return Labour.fromJson(jsonDecode(res.body));
  }

  Future<List<Labour>> getAllLabour() async {
    final res = await _get('/labour/all');
    _throwIfFailed(res);
    final data = jsonDecode(res.body);
    if (data is List) {
      return data.map((e) => Labour.fromJson(e)).toList();
    }
    return [];
  }

  Future<Labour> getLabour(String labourId) async {
    final res = await _get('/labour/$labourId');
    _throwIfFailed(res);
    return Labour.fromJson(jsonDecode(res.body));
  }

  Future<Labour> updateLabour(String labourId, Labour labour) async {
    final res = await _put('/labour/$labourId', body: labour.toJson());
    _throwIfFailed(res);
    return Labour.fromJson(jsonDecode(res.body));
  }

  Future<void> deleteLabour(String labourId) async {
    final res = await _delete('/labour/$labourId');
    _throwIfFailed(res);
  }

  void _throwIfFailed(http.Response res, {bool allowNoContent = false}) {
    final okNoContent = allowNoContent && res.statusCode == 204;
    if (res.statusCode >= 200 && res.statusCode < 300 && !okNoContent) return;
    if (okNoContent) return;
    throw Exception('Request failed (${res.statusCode}): ${res.body}');
  }
}

