import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/local_user.dart';

class AuthDb {
  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'vibe_connect.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            salt TEXT NOT NULL,
            profile_id TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<LocalUser> insertUser({
    required String email,
    required String passwordHash,
    required String salt,
  }) async {
    final db = await database;
    final id = await db.insert('users', {
      'email': email,
      'password_hash': passwordHash,
      'salt': salt,
      'profile_id': null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return LocalUser(id: id, email: email);
  }

  Future<Map<String, dynamic>?> findAuthRowByEmail(String email) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<LocalUser?> findById(int id) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LocalUser.fromMap(rows.first);
  }

  Future<void> updateProfileId(int userId, String? profileId) async {
    final db = await database;
    await db.update(
      'users',
      {'profile_id': profileId},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteUser(int userId) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }
}
