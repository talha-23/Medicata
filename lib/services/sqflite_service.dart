// services/sqflite_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this import for DateFormat
import '../models/medication.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'medicata.db');

    // Delete existing database to ensure clean slate (only for debugging)
    // await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 3, // Increment version to force onCreate/onUpgrade
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onOpen(Database db) async {
    // Verify tables exist when database is opened
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='medications'",
    );

    if (tables.isEmpty) {
      print('Medications table not found! Creating it now...');
      await _createMedicationsTable(db);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Creating database tables for version $version');

    // Create guest session table
    await db.execute('''
      CREATE TABLE guest_session(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        isGuest INTEGER NOT NULL,
        guestId TEXT UNIQUE,
        createdAt TEXT,
        lastLoginAt TEXT,
        name TEXT,
        preferences TEXT
      )
    ''');

    // Create local user data table
    await db.execute('''
      CREATE TABLE user_data(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        dataKey TEXT,
        dataValue TEXT,
        isSynced INTEGER DEFAULT 0,
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

    // Create medications table
    await _createMedicationsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Add medications table if upgrading from version 1
      await _createMedicationsTable(db);
    }

    if (oldVersion < 3) {
      // Add any new columns or tables for version 3
      // Check if tables exist and add missing columns
      await _ensureMedicationsTableColumns(db);
    }
  }

  Future<void> _createMedicationsTable(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS medications(
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          name TEXT NOT NULL,
          numberOfTablets INTEGER NOT NULL,
          dosage TEXT NOT NULL,
          numberOfDays INTEGER NOT NULL,
          notes TEXT,
          createdAt TEXT NOT NULL,
          isActive INTEGER DEFAULT 1,
          imagePath TEXT
        )
      ''');
      print('Medications table created successfully');

      // Create index for faster queries
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_medications_userId ON medications(userId)
      ''');
    } catch (e) {
      print('Error creating medications table: $e');
      rethrow;
    }
  }

  Future<void> markMedicationAsTaken(
    String userId,
    String medicationId,
    DateTime takenAt,
  ) async {
    try {
      final db = await database;
      await db.update(
        'medications',
        {'isTaken': 1, 'takenAt': takenAt.toIso8601String()},
        where: 'id = ? AND userId = ?',
        whereArgs: [medicationId, userId],
      );
      print('Medication $medicationId marked as taken');
    } catch (e) {
      print('Error marking medication as taken: $e');
      rethrow;
    }
  }

  Future<void> _ensureMedicationsTableColumns(Database db) async {
    try {
      // Check if table exists first
      final tableInfo = await db.rawQuery('PRAGMA table_info(medications)');
      final existingColumns = tableInfo
          .map((col) => col['name'] as String)
          .toList();

      // Add any missing columns
      if (!existingColumns.contains('numberOfTablets')) {
        await db.execute(
          'ALTER TABLE medications ADD COLUMN numberOfTablets INTEGER DEFAULT 1',
        );
      }
      if (!existingColumns.contains('numberOfDays')) {
        await db.execute(
          'ALTER TABLE medications ADD COLUMN numberOfDays INTEGER DEFAULT 7',
        );
      }
      if (!existingColumns.contains('isActive')) {
        await db.execute(
          'ALTER TABLE medications ADD COLUMN isActive INTEGER DEFAULT 1',
        );
      }
      if (!existingColumns.contains('imagePath')) {
        await db.execute('ALTER TABLE medications ADD COLUMN imagePath TEXT');
      }

      print('Medications table columns verified');
    } catch (e) {
      print('Error ensuring medications table columns: $e');
    }
  }

  // Add this method to check if table exists
  Future<bool> tableExists(String tableName) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking if table exists: $e');
      return false;
    }
  }

  // ========== MEDICATION METHODS ==========

  Future<void> saveMedication(Medication medication) async {
    try {
      final db = await database;

      // Verify table exists before inserting
      if (!await tableExists('medications')) {
        throw Exception('Medications table does not exist');
      }

      print('Saving medication to database: ${medication.toJson()}');

      final result = await db.insert('medications', {
        'id': medication.id,
        'userId': medication.userId,
        'name': medication.name,
        'numberOfTablets': medication.numberOfTablets,
        'dosage': medication.dosage,
        'numberOfDays': medication.numberOfDays,
        'notes': medication.notes,
        'createdAt': medication.createdAt.toIso8601String(),
        'isActive': medication.isActive ? 1 : 0,
        'imagePath': medication.imagePath,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      print('Medication saved with result: $result');

      // Verify the save
      final saved = await getMedicationById(medication.userId, medication.id);
      if (saved == null) {
        throw Exception('Failed to verify medication was saved');
      }
    } catch (e) {
      print('Error saving medication: $e');
      rethrow;
    }
  }

  Future<List<Medication>> getMedications(String userId) async {
    try {
      final db = await database;

      if (!await tableExists('medications')) {
        print('Medications table does not exist yet');
        return [];
      }

      print('Getting medications for userId: $userId');

      final List<Map<String, dynamic>> results = await db.query(
        'medications',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'createdAt DESC',
      );

      print('Found ${results.length} medications');

      return results.map((json) {
        return Medication(
          id: json['id'] as String,
          name: json['name'] as String,
          numberOfTablets: json['numberOfTablets'] as int,
          dosage: json['dosage'] as String,
          numberOfDays: json['numberOfDays'] as int,
          notes: json['notes'] as String?,
          createdAt: DateTime.parse(json['createdAt'] as String),
          isActive: (json['isActive'] as int) == 1,
          imagePath: json['imagePath'] as String?,
          userId: json['userId'] as String,
        );
      }).toList();
    } catch (e) {
      print('Error getting medications: $e');
      return [];
    }
  }

  Future<Medication?> getMedicationById(
    String userId,
    String medicationId,
  ) async {
    try {
      final db = await database;

      if (!await tableExists('medications')) {
        return null;
      }

      final List<Map<String, dynamic>> results = await db.query(
        'medications',
        where: 'id = ? AND userId = ?',
        whereArgs: [medicationId, userId],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final json = results.first;
      return Medication(
        id: json['id'] as String,
        name: json['name'] as String,
        numberOfTablets: json['numberOfTablets'] as int,
        dosage: json['dosage'] as String,
        numberOfDays: json['numberOfDays'] as int,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isActive: (json['isActive'] as int) == 1,
        imagePath: json['imagePath'] as String?,
        userId: json['userId'] as String,
      );
    } catch (e) {
      print('Error getting medication by ID: $e');
      return null;
    }
  }

  Future<void> updateMedication(Medication medication) async {
    try {
      final db = await database;

      if (!await tableExists('medications')) {
        throw Exception('Medications table does not exist');
      }

      print('Updating medication: ${medication.id}');

      final Map<String, dynamic> updateData = {
        'name': medication.name,
        'numberOfTablets': medication.numberOfTablets,
        'dosage': medication.dosage,
        'numberOfDays': medication.numberOfDays,
        'notes': medication.notes,
        'isActive': medication.isActive ? 1 : 0,
      };

      if (medication.imagePath != null) {
        updateData['imagePath'] = medication.imagePath;
      }

      final result = await db.update(
        'medications',
        updateData,
        where: 'id = ? AND userId = ?',
        whereArgs: [medication.id, medication.userId],
      );

      print('Update result: $result rows affected');

      if (result == 0) {
        throw Exception('Medication not found or not updated');
      }
    } catch (e) {
      print('Error updating medication: $e');
      rethrow;
    }
  }

  Future<void> deleteMedication(String userId, String medicationId) async {
    try {
      final db = await database;

      if (!await tableExists('medications')) {
        throw Exception('Medications table does not exist');
      }

      print('Deleting medication: $medicationId for user: $userId');

      final result = await db.delete(
        'medications',
        where: 'id = ? AND userId = ?',
        whereArgs: [medicationId, userId],
      );

      print('Delete result: $result rows affected');
    } catch (e) {
      print('Error deleting medication: $e');
      rethrow;
    }
  }

  Future<int> getMedicationsCount(String userId) async {
    try {
      final db = await database;

      if (!await tableExists('medications')) {
        return 0;
      }

      final List<Map<String, dynamic>> result = await db.query(
        'medications',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      return result.length;
    } catch (e) {
      print('Error getting medications count: $e');
      return 0;
    }
  }

  Future<List<Medication>> getActiveMedications(String userId) async {
    try {
      final db = await database;

      if (!await tableExists('medications')) {
        return [];
      }

      final List<Map<String, dynamic>> results = await db.query(
        'medications',
        where: 'userId = ? AND isActive = ?',
        whereArgs: [userId, 1],
        orderBy: 'createdAt DESC',
      );

      return results.map((json) {
        return Medication(
          id: json['id'] as String,
          name: json['name'] as String,
          numberOfTablets: json['numberOfTablets'] as int,
          dosage: json['dosage'] as String,
          numberOfDays: json['numberOfDays'] as int,
          notes: json['notes'] as String?,
          createdAt: DateTime.parse(json['createdAt'] as String),
          isActive: true,
          imagePath: json['imagePath'] as String?,
          userId: json['userId'] as String,
        );
      }).toList();
    } catch (e) {
      print('Error getting active medications: $e');
      return [];
    }
  }

  Future<void> toggleMedicationStatus(
    String userId,
    String medicationId,
    bool isActive,
  ) async {
    try {
      final db = await database;

      if (!await tableExists('medications')) {
        throw Exception('Medications table does not exist');
      }

      await db.update(
        'medications',
        {'isActive': isActive ? 1 : 0},
        where: 'id = ? AND userId = ?',
        whereArgs: [medicationId, userId],
      );
    } catch (e) {
      print('Error toggling medication status: $e');
      rethrow;
    }
  }

  Future<void> updateMedicationImage(
    String userId,
    String medicationId,
    String imagePath,
  ) async {
    try {
      final db = await database;

      if (!await tableExists('medications')) {
        throw Exception('Medications table does not exist');
      }

      await db.update(
        'medications',
        {'imagePath': imagePath},
        where: 'id = ? AND userId = ?',
        whereArgs: [medicationId, userId],
      );
    } catch (e) {
      print('Error updating medication image: $e');
      rethrow;
    }
  }

  Future<List<Medication>> searchMedications(
    String userId,
    String searchTerm,
  ) async {
    try {
      final db = await database;

      if (!await tableExists('medications')) {
        return [];
      }

      final List<Map<String, dynamic>> results = await db.query(
        'medications',
        where: 'userId = ? AND name LIKE ?',
        whereArgs: [userId, '%$searchTerm%'],
        orderBy: 'createdAt DESC',
      );

      return results.map((json) {
        return Medication(
          id: json['id'] as String,
          name: json['name'] as String,
          numberOfTablets: json['numberOfTablets'] as int,
          dosage: json['dosage'] as String,
          numberOfDays: json['numberOfDays'] as int,
          notes: json['notes'] as String?,
          createdAt: DateTime.parse(json['createdAt'] as String),
          isActive: (json['isActive'] as int) == 1,
          imagePath: json['imagePath'] as String?,
          userId: json['userId'] as String,
        );
      }).toList();
    } catch (e) {
      print('Error searching medications: $e');
      return [];
    }
  }

  // ========== GUEST SESSION METHODS ==========

  Future<void> createGuestSession({String? name}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';

    await db.insert('guest_session', {
      'isGuest': 1,
      'guestId': guestId,
      'createdAt': now,
      'lastLoginAt': now,
      'name': name ?? 'Guest User',
      'preferences': '{}',
    }, conflictAlgorithm: ConflictAlgorithm.replace);

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
    await db.delete('guest_session', where: 'isGuest = ?', whereArgs: [1]);
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
    await db.insert('user_data', {
      'userId': userId,
      'dataKey': key,
      'dataValue': value,
      'isSynced': synced ? 1 : 0,
      'createdAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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

  // ========== APP SETTINGS / PREFERENCES METHODS ==========

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
      'updatedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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

  // Save user preference in SQLite
  Future<void> saveUserPreference(String key, String value) async {
    try {
      final db = await database;

      // Ensure app_settings table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings(
          key TEXT PRIMARY KEY,
          value TEXT,
          updatedAt TEXT
        )
      ''');

      await db.insert('app_settings', {
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      print('Saved preference: $key = $value');
    } catch (e) {
      print('Error saving user preference: $e');
    }
  }

  // Get user preference from SQLite
  Future<String?> getUserPreference(String key) async {
    try {
      final db = await database;

      // Check if table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='app_settings'",
      );

      if (tables.isEmpty) {
        return null;
      }

      final results = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return results.first['value'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user preference: $e');
      return null;
    }
  }

  // Delete user preference
  Future<void> deleteUserPreference(String key) async {
    try {
      final db = await database;
      await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
    } catch (e) {
      print('Error deleting user preference: $e');
    }
  }

  // Get all user preferences
  Future<Map<String, String>> getAllUserPreferences() async {
    try {
      final db = await database;
      final Map<String, String> preferences = {};

      // Check if table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='app_settings'",
      );

      if (tables.isEmpty) {
        return preferences;
      }

      final results = await db.query('app_settings');

      for (var row in results) {
        final key = row['key'] as String;
        final value = row['value'] as String;
        preferences[key] = value;
      }

      return preferences;
    } catch (e) {
      print('Error getting all user preferences: $e');
      return {};
    }
  }

  // Record medication as taken in history
  Future<void> recordMedicationTaken(
    String userId,
    String medicationId,
    DateTime takenAt,
  ) async {
    try {
      final db = await database;

      // Create history table if not exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS medication_history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          medicationId TEXT NOT NULL,
          takenAt TEXT NOT NULL,
          date TEXT NOT NULL
        )
      ''');

      await db.insert('medication_history', {
        'userId': userId,
        'medicationId': medicationId,
        'takenAt': takenAt.toIso8601String(),
        'date': DateFormat('yyyy-MM-dd').format(takenAt),
      });

      print('Recorded medication taken: $medicationId at $takenAt');
    } catch (e) {
      print('Error recording medication taken: $e');
    }
  }

  // Get medication history for a specific date
  Future<List<Map<String, dynamic>>> getMedicationHistoryForDate(
    String userId,
    String date,
  ) async {
    try {
      final db = await database;

      // Check if table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='medication_history'",
      );

      if (tables.isEmpty) {
        return [];
      }

      final results = await db.query(
        'medication_history',
        where: 'userId = ? AND date = ?',
        whereArgs: [userId, date],
        orderBy: 'takenAt DESC',
      );

      return results;
    } catch (e) {
      print('Error getting medication history: $e');
      return [];
    }
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

  // ========== DEBUG METHODS ==========

  Future<void> debugPrintDatabaseSchema() async {
    try {
      final db = await database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      print('Database tables: $tables');

      for (var table in tables) {
        final tableName = table['name'];
        final columns = await db.rawQuery('PRAGMA table_info($tableName)');
        print('Table $tableName columns: $columns');
      }
    } catch (e) {
      print('Error printing schema: $e');
    }
  }
}
