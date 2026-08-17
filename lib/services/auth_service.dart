import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/local_user.dart';
import 'auth_db.dart';
import 'local_store.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService(this._db, this._store);

  final AuthDb _db;
  final LocalStore _store;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<LocalUser?> restoreSession() async {
    final userId = await _store.readCurrentUserId();
    if (userId == null) return null;
    final user = await _db.findById(userId);
    if (user == null) {
      await _store.clearSession();
      return null;
    }
    return user;
  }

  Future<LocalUser> register({required String email, required String password}) async {
    final normalized = _normalizeEmail(email);
    _validateEmail(normalized);
    _validatePassword(password);

    if (await _db.findAuthRowByEmail(normalized) != null) {
      throw AuthException('An account with this email already exists.');
    }

    final salt = _newSalt();
    final user = await _db.insertUser(
      email: normalized,
      passwordHash: _hashPassword(password, salt),
      salt: salt,
    );
    await _store.saveCurrentUserId(user.id);
    return user;
  }

  Future<LocalUser> login({required String email, required String password}) async {
    final normalized = _normalizeEmail(email);
    _validateEmail(normalized);
    if (password.isEmpty) {
      throw AuthException('Enter your password.');
    }

    final row = await _db.findAuthRowByEmail(normalized);
    if (row == null) {
      throw AuthException('No account found for that email.');
    }
    final salt = row['salt'] as String;
    final expected = row['password_hash'] as String;
    if (_hashPassword(password, salt) != expected) {
      throw AuthException('Incorrect password. Please try again.');
    }

    final user = LocalUser.fromMap(row);
    await _store.saveCurrentUserId(user.id);
    return user;
  }

  Future<void> logout() async {
    await _store.clearSession();
  }

  Future<LocalUser> linkProfile(int userId, String? profileId) async {
    await _db.updateProfileId(userId, profileId);
    if (profileId == null || profileId.isEmpty) {
      await _store.clearProfileId();
    } else {
      await _store.saveProfileId(profileId);
    }
    final user = await _db.findById(userId);
    if (user == null) {
      throw AuthException('Your account could not be found. Please sign in again.');
    }
    return user;
  }

  Future<void> deleteAccount(int userId) async {
    await _db.deleteUser(userId);
    await _store.clearSession();
  }

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  static void _validateEmail(String email) {
    if (email.isEmpty) {
      throw AuthException('Enter your email address.');
    }
    if (!_emailPattern.hasMatch(email)) {
      throw AuthException('Enter a valid email address.');
    }
  }

  static void _validatePassword(String password) {
    if (password.length < 8) {
      throw AuthException('Password must be at least 8 characters.');
    }
  }

  static String _newSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt$password')).toString();
  }
}
