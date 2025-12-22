import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  static String? token;
  static String? role;
  static String? userId;

  static const _kTokenKey = "auth_token";
  static const _kRoleKey = "auth_role";
  static const _kUserIdKey = "auth_user_id";

  // =========================
  // CHECK LOGIN STATUS
  // =========================
  static bool get isLoggedIn => token != null;

  // =========================
  // INITIALIZE STATE (LOAD FROM DISK)
  // =========================
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_kTokenKey);
    role = prefs.getString(_kRoleKey);
    userId = prefs.getString(_kUserIdKey);
  }

  // =========================
  // SAVE LOGIN DATA (✅ NEW)
  // Call this after login success
  // =========================
  static Future<void> setAuthData({
    required String accessToken,
    String? userRole,
    String? id,
  }) async {
    token = accessToken;
    role = userRole;
    userId = id;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, accessToken);
    if (userRole != null) await prefs.setString(_kRoleKey, userRole);
    if (id != null) await prefs.setString(_kUserIdKey, id);
  }

  // =========================
  // CLEAR SESSION (LOGOUT)
  // =========================
  static Future<void> clear() async {
    token = null;
    role = null;
    userId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
