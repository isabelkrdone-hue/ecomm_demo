import 'package:shared_preferences/shared_preferences.dart';

class Sessions {
  static const _keyToken = 'session_token';
  static const _keyUser = 'session_user';
  static const _keyUserId = 'session_user_id';
  static const _keyName = 'session_name';
  static const _keyEmail = 'session_email';
  static const _keyPhone = 'session_phone';
  static const _keyRoleId = 'session_role_id';
  static const _keyRole = 'session_role';
  static const _legacyAccessTokenKey = 'access_token';

  // simple wrapper
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    // write to both the session key and the legacy access_token key for
    // backward compatibility with older versions of the app.
    await prefs.setString(_keyToken, token);
    await prefs.setString(_legacyAccessTokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // prefer the canonical session token key, but fall back to the legacy
    // `access_token` key to survive upgrades / older saved data
    final token = prefs.getString(_keyToken);
    if (token != null && token.isNotEmpty) return token;

    final legacy = prefs.getString(_legacyAccessTokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      // migrate legacy token into canonical key
      await prefs.setString(_keyToken, legacy);
      return legacy;
    }

    return null;
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_legacyAccessTokenKey);
  }

  static Future<void> setLoginSession({
    required String token,
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String roleId,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_legacyAccessTokenKey, token);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyRoleId, roleId);
    await prefs.setString(_keyRole, role);
  }

  static Future<Map<String, String?>> getLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': await getToken(),
      'userId': prefs.getString(_keyUserId),
      'name': prefs.getString(_keyName),
      'email': prefs.getString(_keyEmail),
      'phone': prefs.getString(_keyPhone),
      'roleId': prefs.getString(_keyRoleId),
      'role': prefs.getString(_keyRole),
    };
  }

  static Future<void> clearLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_legacyAccessTokenKey);
    await prefs.remove(_keyUser);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyRoleId);
    await prefs.remove(_keyRole);
  }

  static Future<void> setUser(String userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, userJson);
  }

  static Future<String?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUser);
  }
}
