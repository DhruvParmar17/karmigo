import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  static String? token;
  static String? role;
  static String? userId;
  static String? email; // NEW
  static String? name;  // NEW
  static String? phone; // NEW

  static const _kTokenKey = "auth_token";
  static const _kRoleKey = "auth_role";
  static const _kUserIdKey = "auth_user_id";
  static const _kEmailKey = "auth_email"; // NEW
  static const _kNameKey = "auth_name";   // NEW
  static const _kPhoneKey = "auth_phone"; // NEW

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
    email = prefs.getString(_kEmailKey); // NEW
    name = prefs.getString(_kNameKey);   // NEW
    phone = prefs.getString(_kPhoneKey); // NEW
  }

  // =========================
  // SAVE LOGIN DATA (✅ NEW)
  // Call this after login success
  // =========================
  static Future<void> setAuthData({
    required String accessToken,
    String? userRole,
    String? id,
    String? userEmail, // NEW
    String? userName,  // NEW
    String? userPhone, // NEW
  }) async {
    token = accessToken;
    role = userRole;
    userId = id;
    email = userEmail;
    name = userName;
    phone = userPhone;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, accessToken);
    if (userRole != null) await prefs.setString(_kRoleKey, userRole);
    if (id != null) await prefs.setString(_kUserIdKey, id);
    if (userEmail != null) await prefs.setString(_kEmailKey, userEmail); // NEW
    if (userName != null) await prefs.setString(_kNameKey, userName);    // NEW
    if (userPhone != null) await prefs.setString(_kPhoneKey, userPhone); // NEW
  }

  // =========================
  // CLEAR SESSION (LOGOUT)
  // =========================
  static Future<void> clear() async {
    token = null;
    role = null;
    userId = null;
    email = null;
    name = null;
    phone = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
