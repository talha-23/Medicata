// lib/services/session_manager.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sqflite_service.dart';
import 'package:intl/intl.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Session types
  static const String SESSION_TYPE_NONE = 'none';
  static const String SESSION_TYPE_GUEST = 'guest';
  static const String SESSION_TYPE_REGISTERED = 'registered';

  Future<Map<String, dynamic>> getCurrentSession() async {
    // Check Firebase first (registered user)
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null && firebaseUser.emailVerified) {
      return {
        'type': SESSION_TYPE_REGISTERED,
        'user': firebaseUser,
        'userId': firebaseUser.uid,
        'isGuest': false,
      };
    }

    // Check SQLite for guest session
    bool hasGuestSession = await _dbService.hasActiveGuestSession();
    if (hasGuestSession) {
      final guestData = await _dbService.getActiveGuestSession();
      return {
        'type': SESSION_TYPE_GUEST,
        'user': null,
        'userId': guestData?['guestId'],
        'isGuest': true,
        'guestData': guestData,
      };
    }

    // No active session
    return {
      'type': SESSION_TYPE_NONE,
      'user': null,
      'userId': null,
      'isGuest': false,
    };
  }

  Future<bool> isGuestMode() async {
    final session = await getCurrentSession();
    print('Session type: ${session['type']}'); // Debug
    return session['type'] == SESSION_TYPE_GUEST;
  }

  Future<void> startGuestSession({String? name}) async {
    await _dbService.createGuestSession(name: name);
  }

  Future<void> endGuestSession() async {
    await _dbService.clearGuestSession();
  }

  Future<void> updateGuestActivity() async {
    if (await isGuestMode()) {
      await _dbService.updateGuestLastLogin();
    }
  }

  // Convert guest session to registered user (if they decide to sign up later)
  Future<void> convertGuestToRegistered(String firebaseUid) async {
    if (await isGuestMode()) {
      // Get all guest data
      final guestData = await _dbService.getActiveGuestSession();
      if (guestData != null) {
        final guestId = guestData['guestId'];

        // Migrate guest data to registered user
        final userData = await _dbService.getAllUserData(guestId);
        for (var data in userData) {
          await _dbService.saveUserData(
            userId: firebaseUid,
            key: data['dataKey'],
            value: data['dataValue'],
            synced: false,
          );
        }
      }
      // Clear guest session
      await endGuestSession();
    }
  }

  // Get guest data
  Future<Map<String, dynamic>?> getGuestData() async {
    return await _dbService.getActiveGuestSession();
  }

  // ==================== USER PREFERENCE METHODS ====================

  // Save user preference
  Future<void> saveUserPreference(String key, String value) async {
    try {
      final session = await getCurrentSession();
      
      if (session['type'] == SESSION_TYPE_REGISTERED) {
        // Save to Firestore for registered users
        final userId = session['userId'];
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('preferences')
            .doc(key)
            .set({
          'value': value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (session['type'] == SESSION_TYPE_GUEST) {
        // Save to SQLite for guests
        await _dbService.saveUserPreference(key, value);
      }
    } catch (e) {
      print('Error saving user preference: $e');
    }
  }

  // Get user preference
  Future<String?> getUserPreference(String key) async {
    try {
      final session = await getCurrentSession();
      
      if (session['type'] == SESSION_TYPE_REGISTERED) {
        final userId = session['userId'];
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('preferences')
            .doc(key)
            .get();
        
        if (doc.exists) {
          return doc.data()?['value'] as String?;
        }
      } else if (session['type'] == SESSION_TYPE_GUEST) {
        return await _dbService.getUserPreference(key);
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
      final session = await getCurrentSession();
      
      if (session['type'] == SESSION_TYPE_REGISTERED) {
        final userId = session['userId'];
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('preferences')
            .doc(key)
            .delete();
      } else if (session['type'] == SESSION_TYPE_GUEST) {
        await _dbService.deleteUserPreference(key);
      }
    } catch (e) {
      print('Error deleting user preference: $e');
    }
  }

  // Get all user preferences
  Future<Map<String, String>> getAllUserPreferences() async {
    try {
      final session = await getCurrentSession();
      final Map<String, String> preferences = {};
      
      if (session['type'] == SESSION_TYPE_REGISTERED) {
        final userId = session['userId'];
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('preferences')
            .get();
        
        for (var doc in snapshot.docs) {
          preferences[doc.id] = doc.data()['value'] as String;
        }
      } else if (session['type'] == SESSION_TYPE_GUEST) {
        preferences.addAll(await _dbService.getAllUserPreferences());
      }
      
      return preferences;
    } catch (e) {
      print('Error getting all user preferences: $e');
      return {};
    }
  }

  // ==================== MEDICATION TAKEN STATUS METHODS ====================

  // Save medication taken status for a specific date
  Future<void> saveMedicationTakenStatus(
    String medicationId, 
    String date, 
    bool isTaken
  ) async {
    final key = 'taken_${medicationId}_$date';
    await saveUserPreference(key, isTaken.toString());
  }

  // Get medication taken status for a specific date
  Future<bool> getMedicationTakenStatus(
    String medicationId, 
    String date
  ) async {
    final key = 'taken_${medicationId}_$date';
    final value = await getUserPreference(key);
    return value == 'true';
  }

  // Get all taken statuses for a specific date
  Future<Map<String, bool>> getAllTakenStatusesForDate(String date) async {
    try {
      final allPrefs = await getAllUserPreferences();
      final Map<String, bool> statuses = {};
      
      allPrefs.forEach((key, value) {
        if (key.startsWith('taken_') && key.endsWith('_$date')) {
          final medicationId = key.replaceFirst('taken_', '').replaceFirst('_$date', '');
          statuses[medicationId] = value == 'true';
        }
      });
      
      return statuses;
    } catch (e) {
      print('Error getting all taken statuses: $e');
      return {};
    }
  }

  // Clear old taken statuses (optional - for cleanup)
  Future<void> clearOldTakenStatuses({int daysToKeep = 30}) async {
    try {
      final allPrefs = await getAllUserPreferences();
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffString = DateFormat('yyyy-MM-dd').format(cutoffDate);
      
      for (var entry in allPrefs.entries) {
        if (entry.key.startsWith('taken_')) {
          final datePart = entry.key.split('_').last;
          if (datePart.compareTo(cutoffString) < 0) {
            await deleteUserPreference(entry.key);
          }
        }
      }
    } catch (e) {
      print('Error clearing old taken statuses: $e');
    }
  }
}