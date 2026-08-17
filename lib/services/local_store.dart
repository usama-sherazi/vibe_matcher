import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around shared_preferences for the local session.
class LocalStore {
  static const _profileIdKey = 'vibe_connect.profile_id';
  static const _userIdKey = 'vibe_connect.user_id';

  Future<String?> readProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileIdKey);
  }

  Future<void> saveProfileId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileIdKey, id);
  }

  Future<void> clearProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileIdKey);
  }

  Future<int?> readCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<void> saveCurrentUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, id);
  }

  Future<void> clearCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_profileIdKey);
  }
}
