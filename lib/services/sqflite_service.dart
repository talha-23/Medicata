// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'medicata.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create guest session table
    await db.execute('''
      CREATE TABLE guest_session(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        isGuest BOOLEAN NOT NULL,
        guestId TEXT UNIQUE,
        createdAt TEXT,
        lastLoginAt TEXT,
        name TEXT,
        preferences TEXT
      )
    ''');

    // Create local user data table (for both guest and registered users)
    await db.execute('''
      CREATE TABLE user_data(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        dataKey TEXT,
        dataValue TEXT,
        isSynced BOOLEAN DEFAULT 0,
        createdAt TEXT,
        UNIQUE(userId, dataKey)
      )
    ''');

    // Create app settings table
    await db.execute('''
      CREATE TABLE app_settings(
        key TEXT PRIMARY KEY,
        value TEXT,
        updatedAt TEXT
      )
    ''');
  }

  // ========== GUEST SESSION METHODS ==========

  Future<void> createGuestSession({String? name}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';

    await db.insert(
      'guest_session',
      {
        'isGuest': 1,
        'guestId': guestId,
        'createdAt': now,
        'lastLoginAt': now,
        'name': name ?? 'Guest User',
        'preferences': '{}',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Also store a simple flag in SharedPreferences for quick access
    await _saveGuestFlag(true);
  }

  Future<void> updateGuestLastLogin() async {
    final db = await database;
    await db.update(
      'guest_session',
      {'lastLoginAt': DateTime.now().toIso8601String()},
      where: 'isGuest = ?',
      whereArgs: [1],
    );
  }

  Future<Map<String, dynamic>?> getActiveGuestSession() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'guest_session',
      where: 'isGuest = ?',
      whereArgs: [1],
      orderBy: 'lastLoginAt DESC',
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<bool> hasActiveGuestSession() async {
    final session = await getActiveGuestSession();
    return session != null;
  }

  Future<void> clearGuestSession() async {
    final db = await database;
    await db.delete(
      'guest_session',
      where: 'isGuest = ?',
      whereArgs: [1],
    );
    await _saveGuestFlag(false);
  }

  // ========== LOCAL USER DATA METHODS ==========

  Future<void> saveUserData({
    required String userId,
    required String key,
    required String value,
    bool synced = false,
  }) async {
    final db = await database;
    await db.insert(
      'user_data',
      {
        'userId': userId,
        'dataKey': key,
        'dataValue': value,
        'isSynced': synced ? 1 : 0,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getUserData(String userId, String key) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'user_data',
      where: 'userId = ? AND dataKey = ?',
      whereArgs: [userId, key],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first['dataValue'] as String?;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllUserData(String userId) async {
    final db = await database;
    return await db.query(
      'user_data',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // ========== APP SETTINGS METHODS ==========

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first['value'] as String?;
    }
    return null;
  }

  // ========== SHARED PREFERENCES HELPER ==========

  Future<void> _saveGuestFlag(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest_active', isGuest);
  }

  Future<bool> getGuestFlag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_guest_active') ?? false;
  }

  // ========== CLEANUP ==========

  Future<void> close() async {
    final db = await _database;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}