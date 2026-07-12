import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around shared_preferences. The backend has no auth
/// yet, so the locally-stored profile id *is* the user's identity —
/// keep this key stable.
class LocalStore {
  static const _profileIdKey = 'vibe_connect.profile_id';

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
}
